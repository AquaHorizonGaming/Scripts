from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, EmailStr

class UserCreate(BaseModel):
    email: EmailStr
    password: str
    role: str = 'customer'

class UserRead(BaseModel):
    id: int
    email: EmailStr
    role: str
    is_verified: bool

    class Config:
        orm_mode = True

class Token(BaseModel):
    access_token: str
    token_type: str = 'bearer'

class ProductCreate(BaseModel):
    name: str
    price_shopper: Optional[float] = None
    image_url: Optional[str] = None
    store_id: int = 1

class ProductRead(BaseModel):
    id: int
    name: str
    price_customer: Optional[float]
    image_url: Optional[str]

    class Config:
        orm_mode = True

class AddressCreate(BaseModel):
    street: str
    city: str
    state: str
    zip_code: str

class AddressRead(AddressCreate):
    id: int

    class Config:
        orm_mode = True

class OrderItemCreate(BaseModel):
    product_id: int
    quantity: int = 1

class OrderCreate(BaseModel):
    address_id: int
    items: List[OrderItemCreate]

class OrderRead(BaseModel):
    id: int
    status: str
    created_at: datetime

    class Config:
        orm_mode = True
