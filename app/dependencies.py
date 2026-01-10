from fastapi import Depends, HTTPException, status
from .auth import get_current_user
from . import models


def require_role(role: str):
    def wrapper(user: models.User = Depends(get_current_user)):
        if user.role != role:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN,
                                detail='Insufficient privileges')
        return user
    return wrapper


def require_roles(roles):
    def wrapper(user: models.User = Depends(get_current_user)):
        if user.role not in roles:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN,
                                detail='Insufficient privileges')
        return user
    return wrapper
