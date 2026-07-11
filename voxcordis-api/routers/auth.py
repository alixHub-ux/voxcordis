from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from db import get_session
from db_models import User
from core.auth import verify_password, get_password_hash, create_access_token
from schemas.auth import RegisterRequest

router = APIRouter()


@router.post("/register", status_code=201)
def register(body: RegisterRequest, session: Session = Depends(get_session)):
    import logging
    logger = logging.getLogger("voxcordis")
    try:
        existing = session.query(User).filter(User.email == body.email).first()
        if existing:
            raise HTTPException(status_code=400, detail="Email already registered")
        user = User(
            email=body.email,
            first_name=body.first_name,
            last_name=body.last_name,
            hashed_password=get_password_hash(body.password),
        )
        session.add(user)
        session.commit()
        session.refresh(user)
        access_token = create_access_token({"sub": user.id})
        return {
            "access_token": access_token,
            "token_type": "bearer",
            "user_id": user.id,
            "first_name": user.first_name,
            "last_name": user.last_name,
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.exception("Register failed")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/login")
def login(form: OAuth2PasswordRequestForm = Depends(), session: Session = Depends(get_session)):
    user = session.query(User).filter(User.email == form.username).first()
    if not user or not verify_password(form.password, user.hashed_password):
        raise HTTPException(status_code=400, detail="Incorrect email or password")
    access_token = create_access_token({"sub": user.id})
    return {"access_token": access_token, "token_type": "bearer", "user_id": user.id}
