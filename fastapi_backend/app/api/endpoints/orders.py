from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..deps import get_db, get_current_user
from ... import models, schemas

router = APIRouter(prefix="/orders", tags=["orders"])


@router.post('/', response_model=schemas.Order)
def create_order(order_in: schemas.OrderBase, db: Session = Depends(get_db), user=Depends(get_current_user)):
    cart_items = db.query(models.CartItem).filter(models.CartItem.user_id == user.id).all()
    if not cart_items:
        raise HTTPException(status_code=400, detail="Cart is empty")
    order = models.Order(
        customer_id=user.id,
        scheduled_for=order_in.scheduled_for,
        address=order_in.address,
        phone=order_in.phone,
        notes=order_in.notes,
    )
    db.add(order)
    db.commit()
    for ci in cart_items:
        db.add(models.OrderItem(order_id=order.id, product_id=ci.product_id, quantity=ci.quantity))
    db.query(models.CartItem).filter(models.CartItem.user_id == user.id).delete()
    db.commit()
    db.refresh(order)
    return order


@router.get('/', response_model=list[schemas.Order])
def list_orders(db: Session = Depends(get_db), user=Depends(get_current_user)):
    if user.role == 'admin':
        return db.query(models.Order).all()
    return db.query(models.Order).filter(models.Order.customer_id == user.id).all()
