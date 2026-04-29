from pydantic import BaseModel


class ErrorResponse(BaseModel):
    detail: str
    code: str


class HealthResponse(BaseModel):
    status: str = "ok"
    version: str = "0.1.0"
