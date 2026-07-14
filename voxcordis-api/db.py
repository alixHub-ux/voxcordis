from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker, Session
from core.config import DATABASE_URL
from db_models import Base
import logging

logger = logging.getLogger("voxcordis")

connect_args = {"check_same_thread": False} if "sqlite" in DATABASE_URL else {}
engine = create_engine(DATABASE_URL, echo=False, connect_args=connect_args)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def _schema_version_table_exists(db):
    try:
        db.execute(text("SELECT 1 FROM _schema_version LIMIT 1"))
        return True
    except Exception:
        return False


def _ensure_schema_version_table(db):
    if DATABASE_URL.startswith("sqlite"):
        db.execute(text(
            "CREATE TABLE IF NOT EXISTS _schema_version (version INTEGER NOT NULL)"
        ))
    else:
        db.execute(text(
            "CREATE TABLE IF NOT EXISTS _schema_version (version INTEGER NOT NULL)"
        ))
    db.commit()


def _get_schema_version(db):
    row = db.execute(text("SELECT version FROM _schema_version")).first()
    return row[0] if row else 0


def _set_schema_version(db, version):
    db.execute(text("DELETE FROM _schema_version"))
    db.execute(text(f"INSERT INTO _schema_version (version) VALUES ({version})"))
    db.commit()


SCHEMA_VERSION = 2


def _migrate(db):
    _ensure_schema_version_table(db)
    version = _get_schema_version(db)
    if version < 2:
        for col in ("first_name", "last_name"):
            try:
                db.execute(text(f"ALTER TABLE \"user\" ADD COLUMN {col} TEXT NOT NULL DEFAULT ''"))
            except Exception:
                pass
        _set_schema_version(db, SCHEMA_VERSION)
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

