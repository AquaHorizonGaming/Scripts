import tkinter as tk
from tkinter import ttk, messagebox
import numpy as np
import matplotlib.pyplot as plt


class ToolTip:
    """Simple tooltip implementation for tkinter widgets."""

    def __init__(self, widget, text):
        self.widget = widget
        self.text = text
        self.tipwindow = None
        widget.bind("<Enter>", self.show)
        widget.bind("<Leave>", self.hide)

    def show(self, _event=None):
        if self.tipwindow or not self.text:
            return
        x, y, _cx, cy = self.widget.bbox("insert")
        x = x + self.widget.winfo_rootx() + 25
        y = y + cy + self.widget.winfo_rooty() + 25
        self.tipwindow = tw = tk.Toplevel(self.widget)
        tw.wm_overrideredirect(True)
        tw.wm_geometry("+%d+%d" % (x, y))
        label = tk.Label(
            tw,
            text=self.text,
            justify=tk.LEFT,
            background="#ffffe0",
            relief=tk.SOLID,
            borderwidth=1,
            font=("tahoma", "8", "normal"),
        )
        label.pack(ipadx=1)

    def hide(self, _event=None):
        if self.tipwindow:
            self.tipwindow.destroy()
            self.tipwindow = None


class GBMSimulator(tk.Tk):
    """Main application window for GBM simulation."""

    def __init__(self):
        super().__init__()
        self.title("GBM Simulator")
        self._create_widgets()

    def _create_widgets(self):
        """Create and layout input fields and run button."""
        padding = {"padx": 5, "pady": 5}
        self.entries = {}

        params = [
            ("Initial Value (S₀)", "100"),
            ("Expected Return (mu)", "0.08"),
            ("Volatility (sigma)", "0.2"),
            ("Time Horizon (T)", "1"),
            ("Simulations", "10000"),
            ("Time Steps", "252"),
        ]

        for i, (label_text, default) in enumerate(params):
            label = ttk.Label(self, text=label_text)
            label.grid(row=i, column=0, sticky=tk.E, **padding)
            entry = ttk.Entry(self)
            entry.insert(0, default)
            entry.grid(row=i, column=1, **padding)
            self.entries[label_text] = entry
            ToolTip(entry, f"Enter {label_text.lower()}.")

        self.status_var = tk.StringVar(value="Ready")
        self.status_label = ttk.Label(self, textvariable=self.status_var)
        self.status_label.grid(row=len(params), column=0, columnspan=2, **padding)

        self.run_button = ttk.Button(
            self,
            text="Run Simulation",
            command=self.run_simulation,
        )
        self.run_button.grid(row=len(params) + 1, column=0, columnspan=2, pady=(0, 10))

    def _get_input(self, name, cast):
        """Retrieve and validate user input."""
        value = self.entries[name].get()
        if value == "":
            raise ValueError(f"{name} cannot be blank")
        return cast(value)

    def run_simulation(self):
        """Handle the run button click and perform the simulation."""
        try:
            S0 = self._get_input("Initial Value (S₀)", float)
            mu = self._get_input("Expected Return (mu)", float)
            sigma = self._get_input("Volatility (sigma)", float)
            T = self._get_input("Time Horizon (T)", float)
            n_sim = self._get_input("Simulations", int)
            n_steps = self._get_input("Time Steps", int)
        except Exception as exc:
            messagebox.showerror("Input Error", str(exc))
            return

        self.run_button.config(state=tk.DISABLED)
        self.status_var.set("Running simulation...")
        self.update()

        try:
            dt = T / n_steps
            Z = np.random.normal(size=(n_sim, n_steps))
            increments = (mu - 0.5 * sigma ** 2) * dt + sigma * np.sqrt(dt) * Z
            log_paths = np.cumsum(increments, axis=1)
            paths = S0 * np.exp(log_paths)
            paths = np.column_stack([np.full(n_sim, S0), paths])
            final = paths[:, -1]

            fig, ax = plt.subplots()
            sample_indices = np.random.choice(n_sim, size=min(10, n_sim), replace=False)
            for idx in sample_indices:
                ax.plot(paths[idx], alpha=0.7)
            ax.set_xlabel("Step")
            ax.set_ylabel("Simulated Value")
            title = (
                f"GBM Simulation (S0={S0}, mu={mu}, sigma={sigma}, T={T}, sims={n_sim})"
            )
            ax.set_title(title)
            stats = (
                f"Mean: {final.mean():.2f}\n"
                f"Median: {np.median(final):.2f}\n"
                f"Std: {final.std():.2f}\n"
                f"Min: {final.min():.2f}\n"
                f"Max: {final.max():.2f}"
            )
            plt.figtext(0.15, 0.6, stats, fontsize=9, bbox=dict(facecolor="white", alpha=0.5))
            plt.show()
        except Exception as exc:
            messagebox.showerror("Error", f"An error occurred: {exc}")
        finally:
            self.run_button.config(state=tk.NORMAL)
            self.status_var.set("Ready")


def main():
    app = GBMSimulator()
    app.mainloop()


if __name__ == "__main__":
    main()
