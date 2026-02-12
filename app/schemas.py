from datetime import datetime
from typing import Optional, List

from pydantic import BaseModel, ConfigDict


class UserCreate(BaseModel):
    email: str
    password: str
    role: str = 'customer'


class UserRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    email: str
    role: str
    is_verified: bool


class Token(BaseModel):
    access_token: str
    token_type: str = 'bearer'


class LoginRequest(BaseModel):
    email: str
    password: str


class ProductCreate(BaseModel):
    name: str
    price_shopper: Optional[float] = None
    image_url: Optional[str] = None
    store_id: int = 1


class ProductRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    price_customer: Optional[float]
    image_url: Optional[str]


class AddressCreate(BaseModel):
    street: str
    city: str
    state: str
    zip_code: str


class AddressRead(AddressCreate):
    model_config = ConfigDict(from_attributes=True)

    id: int


class OrderItemCreate(BaseModel):
    product_id: int
    quantity: int = 1


class OrderCreate(BaseModel):
    address_id: int
    items: List[OrderItemCreate]


class OrderRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    status: str
    created_at: datetime
