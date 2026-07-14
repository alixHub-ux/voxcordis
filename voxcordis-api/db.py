from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker, Session
from core.config import DATABASE_URL
from db_models import Base
import logging

logger = logging.getLogger("voxcordis")

connect_args = {"check_same_thread": False} if "sqlite" in DATABASE_URL else {}
engine = create_engine(DATABASE_URL, echo=False, connect_args=connect_args)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


SCHEMA_VERSION = 2


def _migrate(db):
    version = db.execute(text("PRAGMA user_version")).scalar() or 0
    if version < 2:
        for col in ("first_name", "last_name"):
            try:
                db.execute(text(f"ALTER TABLE user ADD COLUMN {col} TEXT NOT NULL DEFAULT ''"))
            except Exception:
                pass
        db.execute(text(f"PRAGMA user_version = {SCHEMA_VERSION}"))
        db.commit()
        logger.info("Schema migrated to version %d", SCHEMA_VERSION)


def init_db():
    Base.metadata.create_all(bind=engine)
    with SessionLocal() as db:
        _migrate(db)


def get_session() -> Session:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

