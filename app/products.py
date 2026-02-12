from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime

from .database import SessionLocal
from . import models, schemas
from .dependencies import require_roles

router = APIRouter(prefix='/products', tags=['products'])


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post('/manual', response_model=schemas.ProductRead, dependencies=[Depends(require_roles(['shopper', 'admin']))])
def add_manual_product(product: schemas.ProductCreate, user: models.User = Depends(require_roles(['shopper', 'admin'])), db: Session = Depends(get_db)):
    db_product = models.Product(
        name=product.name,
        price_shopper=product.price_shopper,
        price_customer=(product.price_shopper + 1.0) if product.price_shopper else None,
        image_url=product.image_url,
        store_id=product.store_id,
        added_by_user=user.id,
        last_verified=datetime.utcnow()
    )
    db.add(db_product)
    db.commit()
    db.refresh(db_product)
    return db_product

@router.get('/', response_model=list[schemas.ProductRead])
def list_products(db: Session = Depends(get_db)):
    products = db.query(models.Product).all()
    result = []
    for p in products:
        if p.price_customer is None:
            result.append({'id': p.id, 'name': p.name, 'price_customer': None, 'image_url': p.image_url, 'label': 'Confirmed at checkout'})
        else:
            result.append(p)
    return result
