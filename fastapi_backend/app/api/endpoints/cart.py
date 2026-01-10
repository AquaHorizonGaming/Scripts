from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy.orm import Session

from ..deps import get_db, get_current_user
from ... import models, schemas

router = APIRouter(prefix="/cart", tags=["cart"])


@router.get("/", response_model=list[schemas.CartItem])
def get_cart(db: Session = Depends(get_db), user=Depends(get_current_user)):
    return db.query(models.CartItem).filter(models.CartItem.user_id == user.id).all()


@router.post("/add", response_model=schemas.CartItem)
def add_cart(item: schemas.CartItemIn, db: Session = Depends(get_db), user=Depends(get_current_user)):
    cart_item = db.query(models.CartItem).filter_by(user_id=user.id, product_id=item.product_id).first()
    if cart_item:
        cart_item.quantity += item.quantity
    else:
        cart_item = models.CartItem(user_id=user.id, product_id=item.product_id, quantity=item.quantity)
        db.add(cart_item)
    db.commit()
    db.refresh(cart_item)
    return cart_item


@router.put("/update", response_model=schemas.CartItem)
def update_cart(item: schemas.CartItemIn, db: Session = Depends(get_db), user=Depends(get_current_user)):
    cart_item = db.query(models.CartItem).filter_by(user_id=user.id, product_id=item.product_id).first()
    if not cart_item:
        raise HTTPException(status_code=404, detail="Item not in cart")
    cart_item.quantity = item.quantity
    db.commit()
    db.refresh(cart_item)
    return cart_item


@router.delete("/remove", status_code=status.HTTP_204_NO_CONTENT)
def remove_cart(item: schemas.CartItemIn, db: Session = Depends(get_db), user=Depends(get_current_user)):
    cart_item = db.query(models.CartItem).filter_by(user_id=user.id, product_id=item.product_id).first()
    if cart_item:
        db.delete(cart_item)
        db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
