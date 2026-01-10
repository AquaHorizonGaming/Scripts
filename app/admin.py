from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from .database import SessionLocal
from . import models, schemas
from .dependencies import require_role

router = APIRouter(prefix='/admin', tags=['admin'])


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.get('/products', response_model=list[schemas.ProductRead])
def list_products(db: Session = Depends(get_db), user: models.User = Depends(require_role('admin'))):
    return db.query(models.Product).all()

@router.post('/products', response_model=schemas.ProductRead)
def create_product(product: schemas.ProductCreate, db: Session = Depends(get_db), user: models.User = Depends(require_role('admin'))):
    db_product = models.Product(
        name=product.name,
        price_shopper=product.price_shopper,
        price_customer=(product.price_shopper + 1.0) if product.price_shopper else None,
        image_url=product.image_url,
        store_id=product.store_id,
        added_by_user=user.id
    )
    db.add(db_product)
    db.commit()
    db.refresh(db_product)
    return db_product

@router.delete('/products/{product_id}')
def delete_product(product_id: int, db: Session = Depends(get_db), user: models.User = Depends(require_role('admin'))):
    product = db.query(models.Product).get(product_id)
    if not product:
        raise HTTPException(status_code=404, detail='Not found')
    db.delete(product)
    db.commit()
    return {'detail': 'deleted'}

@router.get('/jobs')
def list_jobs(db: Session = Depends(get_db), user: models.User = Depends(require_role('admin'))):
    return db.query(models.Job).all()

@router.post('/jobs/{job_id}/assign/{shopper_id}')
def assign_job(job_id: int, shopper_id: int, db: Session = Depends(get_db), user: models.User = Depends(require_role('admin'))):
    job = db.query(models.Job).get(job_id)
    if not job:
        raise HTTPException(status_code=404, detail='Not found')
    job.shopper_id = shopper_id
    job.status = 'assigned'
    db.commit()
    return {'detail': 'assigned'}

@router.get('/users')
def list_users(db: Session = Depends(get_db), user: models.User = Depends(require_role('admin'))):
    return db.query(models.User).all()

@router.post('/users/{user_id}/verify')
def verify_user(user_id: int, db: Session = Depends(get_db), user: models.User = Depends(require_role('admin'))):
    u = db.query(models.User).get(user_id)
    if not u:
        raise HTTPException(status_code=404, detail='Not found')
    u.is_verified = True
    db.commit()
    return {'detail': 'verified'}

@router.post('/users/{user_id}/ban')
def ban_user(user_id: int, db: Session = Depends(get_db), user: models.User = Depends(require_role('admin'))):
    u = db.query(models.User).get(user_id)
    if not u:
        raise HTTPException(status_code=404, detail='Not found')
    u.is_banned = True
    db.commit()
    return {'detail': 'banned'}
