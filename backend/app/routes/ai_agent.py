import requests
import os
from uagents import Agent, Context, Model
from app.utils.kairos_prompt import KAIROS_PROMPT

class ASI1Query(Model):
    query: str
    sender_address: str

class ASI1Response(Model):
    response: str

mainAgent = Agent(
    name="asi1_chat_agent",
    port=5068,
    endpoint="http://localhost:5068/submit",
    seed="kairos_on_chain_agent_111"
)

def get_asi1_response(query: str) -> str:
    api_key = os.environ.get("ASI1_API_KEY")
    if not api_key:
        return "Error: ASI1_API_KEY environment variable not set"

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }

    data = {
    "model": "asi1-mini",
    "messages": [
        {
            "role": "system",
            "content": KAIROS_PROMPT

        },
        {"role": "user", "content": query}
    ]
}



    try:
        response = requests.post("https://api.asi1.ai/v1/chat/completions", json=data, headers=headers)
        if response.status_code == 200:
            result = response.json()
            content = result.get("choices", [{}])[0].get("message", {}).get("content", "").strip()

            return content or "Empty response from ASI1 API"
        else:
            return f"ASI1 API Error {response.status_code}: {response.text}"
    except Exception as e:
        return f"Error contacting ASI1 API: {str(e)}"
    
@mainAgent.on_event("startup")
async def startup(ctx: Context):
    ctx.logger.info(f"Agent {ctx.agent.name} started at {ctx.agent.address}")

@mainAgent.on_message(model=ASI1Query)
async def handle_query(ctx: Context, sender: str, msg: ASI1Query):
    ctx.logger.info(f"Received query: {msg.query}")
    answer = get_asi1_response(msg.query)
    await ctx.send(sender, ASI1Response(reponse=answer))

if __name__ == "__main__":
    mainAgent.run()