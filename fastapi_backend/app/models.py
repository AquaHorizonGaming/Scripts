from sqlalchemy import Column, DateTime, Float, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from .db import Base


class User(Base):
    __tablename__ = 'users'

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(String, index=True, nullable=False, default="customer")
    name = Column(String)
    phone = Column(String)
    address = Column(String)
    is_active = Column(Integer, default=1, nullable=False)

    orders = relationship('Order', back_populates='customer')
    cart_items = relationship('CartItem', back_populates='user')


class Category(Base):
    __tablename__ = 'categories'

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True, nullable=False)

    products = relationship('Product', back_populates='category')


class Product(Base):
    __tablename__ = 'products'

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True, nullable=False)
    image_url = Column(String)
    customer_price = Column(Float, nullable=False)
    shopper_price = Column(Float, nullable=False)
    category_id = Column(Integer, ForeignKey('categories.id'), nullable=False)

    category = relationship('Category', back_populates='products')


class Order(Base):
    __tablename__ = 'orders'

    id = Column(Integer, primary_key=True, index=True)
    customer_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    scheduled_for = Column(DateTime, nullable=False)
    address = Column(String, nullable=False)
    phone = Column(String, nullable=False)
    notes = Column(String)
    status = Column(String, default='pending', nullable=False)

    customer = relationship('User', back_populates='orders')
    items = relationship('OrderItem', back_populates='order')


class OrderItem(Base):
    __tablename__ = 'order_items'

    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey('orders.id'), nullable=False)
    product_id = Column(Integer, ForeignKey('products.id'), nullable=False)
    quantity = Column(Integer, nullable=False)

    order = relationship('Order', back_populates='items')
    product = relationship('Product')


class CartItem(Base):
    __tablename__ = 'cart_items'

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    product_id = Column(Integer, ForeignKey('products.id'), nullable=False)
    quantity = Column(Integer, nullable=False)

    user = relationship('User', back_populates='cart_items')
    product = relationship('Product')
