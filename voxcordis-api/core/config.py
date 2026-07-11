import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

MODEL_PATH = os.getenv("MODEL_PATH", str(BASE_DIR / "models" / "voxcordis_best.keras"))
SCALER_PATH = os.getenv("SCALER_PATH", str(BASE_DIR / "models" / "scaler.pkl"))

TARGET_SR = int(os.getenv("TARGET_SR", "16000"))
MAX_FILE_SIZE = int(os.getenv("MAX_FILE_SIZE", str(10 * 1024 * 1024)))  # 10 MB
ALLOWED_FORMATS = os.getenv(
    "ALLOWED_FORMATS",
    "audio/wav,audio/mpeg,audio/mp4,audio/x-wav,audio/wave"
).split(",")

# ── Auth / Security ───────────────────────────────────────────────────
SECRET_KEY = os.getenv("SECRET_KEY", "change-me")  # override in production with a strong secret
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))

# ── Database ──────────────────────────────────────────────────────────
DATABASE_URL = os.getenv("DATABASE_URL", f"sqlite:///{BASE_DIR / 'voxcordis.db'}")
ALLOWED_ORIGINS = os.getenv("ALLOWED_ORIGINS", "http://localhost:3000").split(",")
