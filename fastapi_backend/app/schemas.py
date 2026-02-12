from datetime import datetime
from enum import Enum
from typing import List, Optional

from pydantic import BaseModel, ConfigDict, Field


class UserRole(str, Enum):
    customer = "customer"
    admin = "admin"


class UserBase(BaseModel):
    email: str
    name: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None


class UserCreate(UserBase):
    password: str = Field(min_length=8)
    role: UserRole = UserRole.customer


class User(UserBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    role: UserRole


class UserUpdate(BaseModel):
    name: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None


class AdminUserUpdate(UserUpdate):
    role: Optional[UserRole] = None
    is_active: Optional[int] = Field(default=None, ge=0, le=1)


class ProductBase(BaseModel):
    name: str
    image_url: Optional[str] = None
    customer_price: float = Field(gt=0)
    shopper_price: float = Field(gt=0)
    category_id: int


class Product(ProductBase):
    model_config = ConfigDict(from_attributes=True)

    id: int


class Category(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str


class OrderItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    product_id: int
    quantity: int = Field(gt=0)


class OrderBase(BaseModel):
    scheduled_for: datetime
    address: str
    phone: str
    notes: Optional[str] = None


class Order(OrderBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    customer_id: int
    status: str
    items: List[OrderItem]


class CartItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    product: Product
    quantity: int


class CartItemIn(BaseModel):
    product_id: int
    quantity: int = Field(gt=0)


class LoginRequest(BaseModel):
    email: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: User
