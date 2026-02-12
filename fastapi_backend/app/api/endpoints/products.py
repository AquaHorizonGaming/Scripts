from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..deps import get_db
from ... import models, schemas

router = APIRouter(prefix="/products", tags=["products"])


@router.get('/', response_model=list[schemas.Product])
def list_products(category_id: int | None = None, db: Session = Depends(get_db)):
    query = db.query(models.Product)
    if category_id:
        query = query.filter(models.Product.category_id == category_id)
    return query.all()


@router.get('/categories/', response_model=list[schemas.Category])
def list_categories(db: Session = Depends(get_db)):
    return db.query(models.Category).all()
