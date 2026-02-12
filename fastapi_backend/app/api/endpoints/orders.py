from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload

from ..deps import get_current_user, get_db
from ... import models, schemas

router = APIRouter(prefix="/orders", tags=["orders"])


@router.post('/', response_model=schemas.Order, status_code=status.HTTP_201_CREATED)
def create_order(order_in: schemas.OrderBase, db: Session = Depends(get_db), user=Depends(get_current_user)):
    cart_items = (
        db.query(models.CartItem)
        .filter(models.CartItem.user_id == user.id)
        .all()
    )
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
    db.flush()

    for ci in cart_items:
        db.add(models.OrderItem(order_id=order.id, product_id=ci.product_id, quantity=ci.quantity))

    db.query(models.CartItem).filter(models.CartItem.user_id == user.id).delete()
    db.commit()

    return (
        db.query(models.Order)
        .options(joinedload(models.Order.items))
        .filter(models.Order.id == order.id)
        .first()
    )


@router.get('/', response_model=list[schemas.Order])
def list_orders(db: Session = Depends(get_db), user=Depends(get_current_user)):
    query = db.query(models.Order).options(joinedload(models.Order.items))
    if user.role == 'admin':
        return query.all()
    return query.filter(models.Order.customer_id == user.id).all()
