"""
Kichkintoy Connect - FastAPI asosiy ilova.
"""
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.core.config import settings
from app.core.database import engine
from app.models import Base

# API routerlar
from app.api.v1 import auth as auth_router
from app.api.v1 import lessons as lessons_router
from app.api.v1 import children as children_router
from app.api.v1 import groups as groups_router
from app.api.v1 import chat as chat_router
from app.api.v1 import content as content_router
from app.api.v1 import admin as admin_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    print(f"🚀 {settings.APP_NAME} ishga tushdi ({settings.APP_ENV})")
    yield
    await engine.dispose()
    print("👋 Ilova o'chirildi")


app = FastAPI(
    title=settings.APP_NAME,
    description="Maktabgacha ta'lim uchun bola-ota-ona-pedagog platformasi",
    version="0.2.0",
    lifespan=lifespan,
)

# CORS
# Eslatma: allow_origins=["*"] + allow_credentials=True brauzer tomonidan bloklanadi.
# DEBUG rejimda localhost uchun regex ishlatiladi.
cors_kwargs = {
    "allow_credentials": True,
    "allow_methods": ["*"],
    "allow_headers": ["*"],
}
if settings.DEBUG:
    cors_kwargs["allow_origins"] = ["http://localhost", "http://127.0.0.1"]
    cors_kwargs["allow_origin_regex"] = r"http://(localhost|127\.0\.0\.1|192\.168\.\d+\.\d+|10\.\d+\.\d+\.\d+)(:\d+)?"
else:
    cors_kwargs["allow_origins"] = settings.CORS_ORIGINS

app.add_middleware(CORSMiddleware, **cors_kwargs)

# Routerlar
app.include_router(auth_router.router, prefix="/api/v1")
app.include_router(lessons_router.router, prefix="/api/v1")
app.include_router(children_router.router, prefix="/api/v1")
app.include_router(groups_router.router, prefix="/api/v1")
app.include_router(groups_router.assignments_router, prefix="/api/v1")
app.include_router(chat_router.router, prefix="/api/v1")
app.include_router(content_router.router, prefix="/api/v1")
app.include_router(admin_router.router, prefix="/api/v1")


@app.get("/", tags=["Asosiy"])
async def root():
    return {
        "app": settings.APP_NAME,
        "version": "0.2.0",
        "status": "ishlayapti",
        "docs": "/docs",
    }


@app.get("/health", tags=["Asosiy"])
async def health_check():
    return JSONResponse({"status": "ok"})


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=settings.DEBUG)
