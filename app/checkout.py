import uuid

from fastapi import APIRouter, Header, HTTPException

from . import schemas
from .cart import clear_cart, get_cart

router = APIRouter(tags=['checkout'])


@router.post('/checkout', response_model=schemas.CheckoutResponse)
def checkout(payload: schemas.CheckoutRequest, x_session_id: str | None = Header(default=None)):
    if not x_session_id:
        raise HTTPException(status_code=400, detail='Missing X-Session-Id header')

    cart = payload.items
    if not cart:
        cart_response = get_cart(x_session_id)
        cart = cart_response.items

    if not cart:
        raise HTTPException(status_code=400, detail='Cart is empty')

    total = round(sum(item.unit_price * item.quantity for item in cart), 2)
    order_id = f'ORD-{uuid.uuid4().hex[:10].upper()}'

    clear_cart(x_session_id)

    return schemas.CheckoutResponse(
        status='OK',
        order_id=order_id,
        message='Order Received — Thank you!',
        total=total,
        items=cart,
    )
