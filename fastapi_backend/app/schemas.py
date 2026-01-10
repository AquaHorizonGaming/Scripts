from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, EmailStr

class UserBase(BaseModel):
    email: EmailStr

class UserCreate(UserBase):
    password: str
    role: str = 'customer'

class User(UserBase):
    id: int
    role: str

    class Config:
        orm_mode = True

class ProductBase(BaseModel):
    name: str
    image_url: Optional[str] = None
    customer_price: float
    shopper_price: float

class Product(ProductBase):
    id: int

    class Config:
        orm_mode = True

class OrderItem(BaseModel):
    product_id: int
    quantity: int

class OrderBase(BaseModel):
    scheduled_for: datetime

class OrderCreate(OrderBase):
    items: List[OrderItem]

class Order(OrderBase):
    id: int
    customer_id: int
    status: str
    items: List[OrderItem]

    class Config:
        orm_mode = True
