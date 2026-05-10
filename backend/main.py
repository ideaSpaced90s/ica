import os
import re
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from sarvamai import SarvamAI
from dotenv import load_dotenv

# Load the Secret Vault (Looking in root and backend folders)
load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), '..', '.env'))
load_dotenv() # Fallback to local .env if present

app = FastAPI(title="Kingslayer Board Council")

# The Council's Open Gate (CORS)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# The Oracle of Sarvam (using the Magic Cloud Library)
SARVAM_API_KEY = os.getenv("SARVAM_API_KEY")
client = SarvamAI(api_subscription_key=SARVAM_API_KEY) if SARVAM_API_KEY else None
SARVAM_MODEL = os.getenv("SARVAM_MODEL", "sarvam-m")

class MoveContext(BaseModel):
    player: str
    move: str
    eval_score: str
    history: str = ""

@app.get("/")
async def health_check():
    return {"status": "The Council is wise and ready."}

@app.post("/generate_commentary")
async def generate_commentary(context: MoveContext):
    if not client:
        raise HTTPException(status_code=500, detail="Sarvam API Key missing from .env")

    try:
        system_prompt = (
            "You are the High Council of Chess, a sophisticated and dramatic narrator. "
            "Provide personal, dynamic commentary under 150 characters based on the specific move. "
            "Avoid generic phrases or repeating previous tone exactly. "
            "Never include your internal reasoning or 'thought' process in the output."
        )

        user_input = f"Player: {context.player}, Move: {context.move}, Eval: {context.eval_score}. Context: {context.history}"

        response = client.chat.completions(
            model=SARVAM_MODEL,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_input}
            ]
        )

        raw_content = response.choices[0].message.content
        
        # Strip internal thought monologue (even if tags are unclosed or spanning lines)
        # 1. Strip <think>...</think>
        commentary = re.sub(r'<think>.*?</think>', '', raw_content, flags=re.DOTALL)
        # 2. Strip unclosed <think> blocks
        commentary = re.sub(r'<think>.*$', '', commentary, flags=re.DOTALL)
        # 3. Final cleaning
        commentary = commentary.strip()
        
        # Ensure it fits the character limits
        if len(commentary) > 150:
            commentary = commentary[:147] + "..."
            
        return {"commentary": commentary}

    except Exception as e:
        print(f"Council Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
