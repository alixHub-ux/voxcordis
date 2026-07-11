from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from db import get_session
from db_models import User
from core.auth import verify_password, get_password_hash, create_access_token

router = APIRouter()


@router.post("/register")
def register(form: OAuth2PasswordRequestForm = Depends(), session: Session = Depends(get_session)):
    existing = session.query(User).filter(User.email == form.username).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")
    user = User(email=form.username, hashed_password=get_password_hash(form.password))
    session.add(user)
    session.commit()
    session.refresh(user)
    access_token = create_access_token({"sub": user.id})
    return {"access_token": access_token, "token_type": "bearer", "user_id": user.id}


@router.post("/login")
def login(form: OAuth2PasswordRequestForm = Depends(), session: Session = Depends(get_session)):
    user = session.query(User).filter(User.email == form.username).first()
    if not user or not verify_password(form.password, user.hashed_password):
        raise HTTPException(status_code=400, detail="Incorrect email or password")
    access_token = create_access_token({"sub": user.id})
    return {"access_token": access_token, "token_type": "bearer", "user_id": user.id}
