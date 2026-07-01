"""Bus Defect Reporting API — FastAPI application entry point."""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .accounts import ensure_bootstrap_admin
from .config import settings
from .database import init_db
from .routers import auth, defects, users

logger = logging.getLogger("uvicorn.error")


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    ensure_bootstrap_admin()
    if settings.is_secret_insecure:
        logger.warning(
            "SECRET_KEY is the insecure default — set a strong SECRET_KEY "
            "before deploying to production."
        )
    if settings.origins_list == ["*"]:
        logger.warning(
            "CORS is open to all origins — set ALLOWED_ORIGINS to your app's "
            "domain before deploying to production."
        )
    yield


app = FastAPI(
    title="Bus Defect Reporting API",
    version="1.0.0",
    description="REST backend for the bus defect reporting Flutter app.",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(users.router)
app.include_router(defects.router)


@app.get("/", tags=["health"])
def health():
    return {"status": "ok", "service": "bus-defect-api"}
