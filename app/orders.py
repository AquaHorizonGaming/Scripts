from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime

from .database import SessionLocal
from . import models, schemas
from .dependencies import require_role, require_roles

router = APIRouter(prefix='/orders', tags=['orders'])


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post('/', response_model=schemas.OrderRead, dependencies=[Depends(require_role('customer'))])
def create_order(order: schemas.OrderCreate, user: models.User = Depends(require_role('customer')), db: Session = Depends(get_db)):
    db_order = models.Order(user_id=user.id, address_id=order.address_id)
    db.add(db_order)
    db.commit()
    db.refresh(db_order)
    for item in order.items:
        db_item = models.OrderItem(order_id=db_order.id, product_id=item.product_id, quantity=item.quantity)
        db.add(db_item)
    db_job = models.Job(order_id=db_order.id)
    db.add(db_job)
    db.commit()
    return db_order

@router.get('/{order_id}', response_model=schemas.OrderRead)
def get_order(order_id: int, user: models.User = Depends(require_roles(['customer', 'shopper', 'admin'])), db: Session = Depends(get_db)):
    order = db.query(models.Order).get(order_id)
    if not order:
        raise HTTPException(status_code=404, detail='Not found')
    return order

@router.post('/{order_id}/status/{status}', dependencies=[Depends(require_role('shopper'))])
def update_status(order_id: int, status: str, user: models.User = Depends(require_role('shopper')), db: Session = Depends(get_db)):
    job = db.query(models.Job).filter_by(order_id=order_id, shopper_id=user.id).first()
    if not job:
        raise HTTPException(status_code=404, detail='Job not found')
    job.status = status
    db.commit()
    return {'detail': 'updated'}
