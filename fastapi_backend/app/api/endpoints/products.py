from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..deps import get_db
from ... import models, schemas

router = APIRouter(prefix="/products", tags=["products"])


@router.get('/', response_model=list[schemas.Product])
def list_products(db: Session = Depends(get_db)):
    return db.query(models.Product).all()
