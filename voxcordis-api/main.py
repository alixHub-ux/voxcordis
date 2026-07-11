import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from core.config import ALLOWED_ORIGINS
from db import init_db

# routers
from routers import auth as auth_router
from routers import analysis as analysis_router

# ── Logging ────────────────────────────────────────────────────────────
logging.basicConfig(
    level    = logging.INFO,
    format   = "%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt  = "%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("voxcordis")

# ── App initialization ────────────────────────────────────────────────
app = FastAPI(
    title       = "Voxcordis API",
    description = (
        "REST API for cardiovascular risk screening "
        "through voice analysis. "
        "Powered by YAMNet + TensorFlow."
    ),
    version     = "1.1.0",
    contact     = {
        "name"  : "VEBAMBA A Carine",
        "email" : "carinecontact.dev@gmail.com"
    }
)

# ── CORS Middleware ───────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins     = ALLOWED_ORIGINS,
    allow_methods     = ["*"],
    allow_headers     = ["*"],
)


@app.on_event("startup")
def on_startup():
    # initialise database and any other startup tasks
    init_db()
    logger.info("Database initialized.")


# ── Health check ──────────────────────────────────────────────────────
@app.get("/")
def root():
    return {
        "status"      : "online",
        "app"         : "Voxcordis API",
        "version"     : "1.1.0",
        "description" : "Cardiovascular risk screening through voice analysis"
    }


# ── Include routers ───────────────────────────────────────────────────
app.include_router(auth_router.router, prefix="/auth", tags=["auth"])
app.include_router(analysis_router.router, prefix="/analysis", tags=["analysis"])


# ── Run directly ──────────────────────────────────────────────────────
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=7860, reload=True)
