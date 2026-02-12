from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..deps import get_db, get_current_user
from ... import models, schemas

router = APIRouter(prefix="/admin", tags=["admin"])


def current_admin(user: models.User = Depends(get_current_user)):
    if user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized")
    return user


@router.get("/users", response_model=list[schemas.User])
def list_users(db: Session = Depends(get_db), admin: models.User = Depends(current_admin)):
    return db.query(models.User).all()


@router.put("/users/{user_id}", response_model=schemas.User)
def update_user_role(user_id: int, payload: schemas.UserUpdate, db: Session = Depends(get_db), admin: models.User = Depends(current_admin)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    data = payload.dict(exclude_unset=True)
    for field, value in data.items():
        setattr(user, field, value)
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@router.delete("/users/{user_id}")
def deactivate_user(user_id: int, db: Session = Depends(get_db), admin: models.User = Depends(current_admin)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.is_active = 0
    db.add(user)
    db.commit()
    return {"detail": "deactivated"}


@router.post("/products", response_model=schemas.Product)
def add_product(product: schemas.ProductBase, db: Session = Depends(get_db), admin: models.User = Depends(current_admin)):
    p = models.Product(**product.dict())
    db.add(p)
    db.commit()
    db.refresh(p)
    return p


@router.put("/products/{product_id}", response_model=schemas.Product)
def update_product(product_id: int, product: schemas.ProductBase, db: Session = Depends(get_db), admin: models.User = Depends(current_admin)):
    p = db.query(models.Product).filter(models.Product.id == product_id).first()
    if not p:
        raise HTTPException(status_code=404, detail="Product not found")
    for field, value in product.dict().items():
        setattr(p, field, value)
    db.add(p)
    db.commit()
    db.refresh(p)
    return p


@router.delete("/products/{product_id}")
def delete_product(product_id: int, db: Session = Depends(get_db), admin: models.User = Depends(current_admin)):
    p = db.query(models.Product).filter(models.Product.id == product_id).first()
    if p:
        db.delete(p)
        db.commit()
    return {"detail": "deleted"}
