from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..deps import get_db, get_current_user
from ... import models, schemas

router = APIRouter(prefix="/orders", tags=["orders"])


@router.post('/', response_model=schemas.Order)
def create_order(order_in: schemas.OrderCreate, db: Session = Depends(get_db), user=Depends(get_current_user)):
    order = models.Order(customer_id=user.id, scheduled_for=order_in.scheduled_for)
    db.add(order)
    db.commit()
    for item in order_in.items:
        db.add(models.OrderItem(order_id=order.id, product_id=item.product_id, quantity=item.quantity))
    db.commit()
    db.refresh(order)
    return order


@router.get('/', response_model=list[schemas.Order])
def list_orders(db: Session = Depends(get_db), user=Depends(get_current_user)):
    return db.query(models.Order).filter(models.Order.customer_id == user.id).all()
