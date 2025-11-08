import os
from dotenv import load_dotenv
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from app.routes.ai_agent import get_asi1_response
from app.utils.format import parse_and_extract_ai_response

load_dotenv()

ALLOWED_ORIGINS = ["http://localhost:3000"]

app = FastAPI(title="Kairos")
app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class UserQuery(BaseModel):
    question: str


@app.post("/ask")
async def ask_ai(request: Request):
    data = await request.json()
    question = data.get("question", "")
    answer = get_asi1_response(question)
    workflow = parse_and_extract_ai_response(answer)
    
    return {"workflow": workflow}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5000, reload=True)
