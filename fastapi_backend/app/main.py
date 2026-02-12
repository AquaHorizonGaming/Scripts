from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

from .api.endpoints import admin, auth, cart, orders, products, users
from .config import settings
from .db import Base, engine

Base.metadata.create_all(bind=engine)

app = FastAPI(title=settings.app_name)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

repo_root = Path(__file__).resolve().parents[2]
web_root = repo_root / "grocery_web"

if web_root.exists():
    app.mount("/static", StaticFiles(directory=web_root), name="static")


@app.get("/health")
def health_check():
    return {"status": "ok", "environment": settings.environment}


@app.get("/")
def storefront_home():
    index_path = web_root / "index.html"
    if index_path.exists():
        return FileResponse(index_path)
    return {"message": "Storefront not found", "hint": "Expected grocery_web/index.html"}


@app.get("/app.js")
def storefront_js():
    return FileResponse(web_root / "app.js")


@app.get("/styles.css")
def storefront_css():
    return FileResponse(web_root / "styles.css")


app.include_router(auth.router)
app.include_router(products.router)
app.include_router(orders.router)
app.include_router(users.router)
app.include_router(cart.router)
app.include_router(admin.router)
