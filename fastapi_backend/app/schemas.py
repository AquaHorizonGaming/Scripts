from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, EmailStr

class UserBase(BaseModel):
    email: EmailStr
    name: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None

class UserCreate(UserBase):
    password: str
    role: str = 'customer'

class User(UserBase):
    id: int
    role: str

    class Config:
        orm_mode = True


class UserUpdate(BaseModel):
    name: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None

class ProductBase(BaseModel):
    name: str
    image_url: Optional[str] = None
    customer_price: float
    shopper_price: float

class Product(ProductBase):
    id: int

    class Config:
        orm_mode = True


class Category(BaseModel):
    id: int
    name: str

    class Config:
        orm_mode = True

class OrderItem(BaseModel):
    product_id: int
    quantity: int

class OrderBase(BaseModel):
    scheduled_for: datetime
    address: str
    phone: str
    notes: Optional[str] = None

class OrderCreate(OrderBase):
    items: List[OrderItem]

class Order(OrderBase):
    id: int
    customer_id: int
    status: str
    items: List[OrderItem]

    class Config:
        orm_mode = True


class CartItem(BaseModel):
    id: int
    product: Product
    quantity: int

    class Config:
        orm_mode = True


class CartItemIn(BaseModel):
    product_id: int
    quantity: int
