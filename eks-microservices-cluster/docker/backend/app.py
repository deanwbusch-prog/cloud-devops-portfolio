from fastapi import FastAPI
from pydantic import BaseModel
import uvicorn
import os

app = FastAPI()

class Echo(BaseModel):
    message: str

@app.get("/api/health")
def health():
    return {"status": "ok"}

@app.get("/api/info")
def info():
    return {
        "service": "backend",
        "env": os.environ.get("APP_ENV", "dev")
    }

@app.post("/api/echo")
def echo(payload: Echo):
    return {"echo": payload.message}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", "5000")))
