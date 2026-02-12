#!/bin/bash

############################################
# Riven Media File Validator (Fully Manual)
############################################

LOG_DIR="/tmp/riven_validation_logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/broken_files_$TIMESTAMP.log"
SUMMARY_FILE="$LOG_DIR/validation_summary_$TIMESTAMP.txt"
BROKEN_EPISODES_FILE="$LOG_DIR/broken_episodes_$TIMESTAMP.csv"
BROKEN_MOVIES_FILE="$LOG_DIR/broken_movies_$TIMESTAMP.csv"

READ_SIZE=1048576

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

mkdir -p "$LOG_DIR"

############################################
# Mount Path Input
############################################
echo "========================================"
echo "Riven Media File Validator"
echo "========================================"
echo ""
echo "Enter mount paths to scan."
echo "One per line. Leave blank when finished."
echo ""

SELECTED_MOUNTS=()
while true; do
    read -p "Mount path: " m
    [[ -z "$m" ]] && break
    if [[ -d "$m" ]]; then
        SELECTED_MOUNTS+=("$m")
    else
        echo "⚠ Path does not exist, skipped"
    fi
done

if [[ ${#SELECTED_MOUNTS[@]} -eq 0 ]]; then
    echo "❌ No valid mount paths provided."
    exit 1
fi

############################################
# Content Path Configuration
############################################
echo ""
echo "=== Content Path Configuration ==="

declare -A CONTENT_PATHS
SEARCH_KEYS=()

ask_content() {
    local key="$1"
    local label="$2"
    read -p "Do you have $label? (y/n): " ans
    if [[ "$ans" =~ ^[Yy] ]]; then
        read -p "Enter FULL path to $label directory: " p
        if [[ -d "$p" ]]; then
            CONTENT_PATHS["$key"]="$p"
            SEARCH_KEYS+=("$key")
        else
            echo "⚠ Invalid path, skipping $label"
        fi
    fi
}

ask_content "tv" "TV Shows"
ask_content "movies" "Movies"

read -p "Do you have Anime content? (y/n): " has_anime
if [[ "$has_anime" =~ ^[Yy] ]]; then
    ask_content "anime_tv" "Anime TV Shows"
    ask_content "anime_movies" "Anime Movies"
fi

if [[ ${#SEARCH_KEYS[@]} -eq 0 ]]; then
    echo "❌ No content paths configured."
    exit 1
fi

echo ""
echo "Configured content paths:"
for k in "${SEARCH_KEYS[@]}"; do
    echo "  - $k → ${CONTENT_PATHS[$k]}"
done

############################################
# Test Mode
############################################
echo ""
read -p "Test ALL files or SAMPLE? (all/sample): " test_mode
if [[ "$test_mode" == "sample" ]]; then
    read -p "How many files per season / directory? " sample_size
fi

############################################
# Helpers
############################################
validate_file() {
    [[ -f "$1" && -r "$1" ]] || return 1
    timeout 10 dd if="$1" of=/dev/null bs="$READ_SIZE" count=1 iflag=direct 2>/dev/null
}

extract_show_info() {
    local path="$1"
    show="$(basename "$(dirname "$(dirname "$path")")")"
    ep="$(basename "$path" | grep -oP '[Ss]\d+[Ee]\d+|\d+[xX]\d+' | head -1)"
    season=""
    episode=""

    if [[ "$ep" =~ [Ss]([0-9]+)[Ee]([0-9]+) ]]; then
        season="${BASH_REMATCH[1]}"
        episode="${BASH_REMATCH[2]}"
    elif [[ "$ep" =~ ([0-9]+)[xX]([0-9]+) ]]; then
        season="${BASH_REMATCH[1]}"
        episode="${BASH_REMATCH[2]}"
    fi

    echo "$show|$season|$episode"
}

############################################
# Init Logs
############################################
echo "show_name,season,episode,path,mount" > "$BROKEN_EPISODES_FILE"
echo "movie_name,path,mount" > "$BROKEN_MOVIES_FILE"

declare -A flagged_seasons
declare -a broken_movie_names

total_files=0
tested_files=0
broken_files=0
accessible_files=0

############################################
# Main Scan
############################################
for mount in "${SELECTED_MOUNTS[@]}"; do
    for key in "${SEARCH_KEYS[@]}"; do
        search_path="${CONTENT_PATHS[$key]}"
        [[ "$search_path" != "$mount"* ]] && continue
        [[ -d "$search_path" ]] || continue

        echo ""
        echo "Scanning: $search_path"

        mapfile -t files < <(
            find "$search_path" -type f \
            \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.m4v" -o -iname "*.mov" \) 2>/dev/null
        )

        total_files=$((total_files + ${#files[@]}))

        if [[ "$test_mode" == "sample" && ${#files[@]} -gt $sample_size ]]; then
            mapfile -t files < <(printf '%s\n' "${files[@]}" | shuf -n "$sample_size")
        fi

        for file in "${files[@]}"; do
            tested_files=$((tested_files + 1))

            if validate_file "$file"; then
                accessible_files=$((accessible_files + 1))
            else
                broken_files=$((broken_files + 1))
                relative="${file#$mount/}"

                if [[ "$key" == "tv" || "$key" == "anime_tv" ]]; then
                    info=$(extract_show_info "$file")
                    IFS='|' read -r show season episode <<< "$info"
                    [[ -n "$show" && -n "$season" ]] && flagged_seasons["$show::$season"]=1
                    echo "\"$show\",\"$season\",\"$episode\",\"$relative\",\"$mount\"" >> "$BROKEN_EPISODES_FILE"
                else
                    movie="$(basename "$(dirname "$file")")"
                    broken_movie_names+=("$movie")
                    echo "\"$movie\",\"$relative\",\"$mount\"" >> "$BROKEN_MOVIES_FILE"
                fi

                echo "BROKEN: $file" >> "$LOG_FILE"
                echo -e "${RED}✗ BROKEN:${NC} $file"
            fi
        done
    done
done

############################################
# Summary
############################################
cat > "$SUMMARY_FILE" << EOF
Riven Media File Validation Summary
Generated: $(date)

Mounts:
$(printf '  - %s\n' "${SELECTED_MOUNTS[@]}")

Content Paths:
$(for k in "${SEARCH_KEYS[@]}"; do echo "  - $k → ${CONTENT_PATHS[$k]}"; done)

Results:
  Total files found: $total_files
  Files tested: $tested_files
  Accessible files: $accessible_files
  Broken files: $broken_files
EOF

echo ""
echo -e "${GREEN}Validation complete${NC}"
echo "Summary: $SUMMARY_FILE"
echo "Logs:    $LOG_DIR"
echo ""
echo "Done."