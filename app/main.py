from pathlib import Path

from fastapi import FastAPI
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

from . import admin, auth, orders, products
from .database import Base, engine

app = FastAPI(title='Grocery Delivery API')

Base.metadata.create_all(bind=engine)

repo_root = Path(__file__).resolve().parents[1]
web_root = repo_root / "grocery_web"

if web_root.exists():
    app.mount('/static', StaticFiles(directory=web_root), name='store-static')


@app.get('/')
def storefront_home():
    index_path = web_root / 'index.html'
    if index_path.exists():
        return FileResponse(index_path)
    return {'detail': 'Storefront not found'}


@app.get('/app.js')
def storefront_js():
    return FileResponse(web_root / 'app.js')


@app.get('/styles.css')
def storefront_css():
    return FileResponse(web_root / 'styles.css')


app.include_router(auth.router)
app.include_router(products.router)
app.include_router(orders.router)
app.include_router(admin.router)
