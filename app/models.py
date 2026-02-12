from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, ForeignKey, Boolean, DateTime
from sqlalchemy.orm import relationship
from .database import Base

class User(Base):
    __tablename__ = 'users'
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(String, default='customer')
    is_verified = Column(Boolean, default=False)
    is_banned = Column(Boolean, default=False)
    products = relationship('Product', back_populates='added_by')

class Product(Base):
    __tablename__ = 'products'
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True, nullable=False)
    price_shopper = Column(Float)
    price_customer = Column(Float)
    image_url = Column(String)
    store_id = Column(Integer, default=1)
    added_by_user = Column(Integer, ForeignKey('users.id'))
    verified_by = Column(Integer, ForeignKey('users.id'), nullable=True)
    last_verified = Column(DateTime)
    added_by = relationship('User', foreign_keys=[added_by_user], back_populates='products')

class Address(Base):
    __tablename__ = 'addresses'
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'))
    street = Column(String)
    city = Column(String)
    state = Column(String)
    zip_code = Column(String)

class Order(Base):
    __tablename__ = 'orders'
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'))
    address_id = Column(Integer, ForeignKey('addresses.id'))
    status = Column(String, default='created')
    created_at = Column(DateTime, default=datetime.utcnow)

class OrderItem(Base):
    __tablename__ = 'order_items'
    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey('orders.id'))
    product_id = Column(Integer, ForeignKey('products.id'))
    quantity = Column(Integer, default=1)

class Job(Base):
    __tablename__ = 'jobs'
    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey('orders.id'))
    shopper_id = Column(Integer, ForeignKey('users.id'), nullable=True)
    status = Column(String, default='unclaimed')
