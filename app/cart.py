from collections import defaultdict
from typing import Dict

from fastapi import APIRouter, Header, HTTPException

from . import schemas

router = APIRouter(prefix='/cart', tags=['cart'])

# In-memory cart store by session
_CARTS: Dict[str, Dict[int, schemas.CartItem]] = defaultdict(dict)


def _session_id(x_session_id: str | None) -> str:
    if not x_session_id:
        raise HTTPException(status_code=400, detail='Missing X-Session-Id header')
    return x_session_id


def _cart_response(session_id: str) -> schemas.CartResponse:
    items = list(_CARTS[session_id].values())
    total = round(sum(item.unit_price * item.quantity for item in items), 2)
    return schemas.CartResponse(items=items, total=total)


@router.get('', response_model=schemas.CartResponse)
def get_cart(x_session_id: str | None = Header(default=None)):
    session_id = _session_id(x_session_id)
    return _cart_response(session_id)


@router.post('/add', response_model=schemas.CartResponse)
def add_to_cart(payload: schemas.CartAddRequest, x_session_id: str | None = Header(default=None)):
    session_id = _session_id(x_session_id)

    cart = _CARTS[session_id]
    existing = cart.get(payload.product_id)

    if existing:
        existing.quantity += payload.quantity
    else:
        cart[payload.product_id] = schemas.CartItem(
            product_id=payload.product_id,
            name=payload.name,
            unit_price=payload.unit_price,
            quantity=payload.quantity,
        )

    return _cart_response(session_id)


@router.put('/update', response_model=schemas.CartResponse)
def update_cart(payload: schemas.CartUpdateRequest, x_session_id: str | None = Header(default=None)):
    session_id = _session_id(x_session_id)

    cart = _CARTS[session_id]
    item = cart.get(payload.product_id)
    if not item:
        raise HTTPException(status_code=404, detail='Product not in cart')

    if payload.quantity <= 0:
        del cart[payload.product_id]
    else:
        item.quantity = payload.quantity

    return _cart_response(session_id)


@router.post('/remove', response_model=schemas.CartResponse)
def remove_from_cart(payload: schemas.CartRemoveRequest, x_session_id: str | None = Header(default=None)):
    session_id = _session_id(x_session_id)
    _CARTS[session_id].pop(payload.product_id, None)
    return _cart_response(session_id)


def clear_cart(session_id: str):
    _CARTS[session_id] = {}
