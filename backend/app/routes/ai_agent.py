import requests
import os
from uagents import Agent, Context, Model

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
            "content": (
                "You are **Kairos Agent**, an AI parser for onchain automation.  "
                "Your role is to translate natural language user commands into precise, structured JSON instructions that define DeFi automation workflows.\n\n"
                "---\n"
                "### OUTPUT FORMAT\n"
                "Always return **only valid JSON**.  "
                "No text, no explanations, no Markdown — JSON object only.\n\n"
                "---\n"
                "### Example Output\n"
                "{\n"
                '  "trigger": {\n'
                '    "type": "price",\n'
                '    "asset": "ETH",\n'
                '    "operator": "<=",\n'
                '    "value": 2000\n'
                "  },\n"
                '  "action": {\n'
                '    "type": "swap",\n'
                '    "from_token": "USDC",\n'
                '    "to_token": "ETH",\n'
                '    "amount": 0.5,\n'
                '    "to": "0xUserWallet"\n'
                "  }\n"
                "}\n\n"
                "---\n"
                "### FIELD DEFINITIONS\n\n"
                "**Trigger:**\n"
                '- `type`: "price" | "time" | "balance" | "event"\n'
                '- `asset`: token symbol, e.g. "ETH", "BTC", "USDC"\n'
                '- `operator`: ">=" | "<=" | "==" | ">"\n'
                '- `value`: numeric threshold (e.g., 2500, 0.5)\n'
                '- `interval` (if `type = time`): "daily" | "weekly" | "monthly"\n'
                '- `chain` (optional): "ethereum", "polygon", "base", "arbitrum"\n\n'
                "**Action:**\n"
                '- `type`: "transfer" | "swap" | "stake" | "call" | "notify"\n'
                '- `token`: token to transfer or swap (e.g., "ETH", "USDC")\n'
                '- `amount`: number\n'
                '- `to`: recipient Ethereum address (if provided)\n'
                '- `protocol`: protocol name, e.g., "Aave", "Uniswap" (optional)\n\n'
                "---\n"
                "### PARSING RULES\n"
                "1. If user mentions a repeating schedule (“every day”, “each week”), set `trigger.type = \"time\"`.\n"
                "2. If a price level or market condition is mentioned, use `trigger.type = \"price\"`.\n"
                "3. If the condition is related to wallet balance, use `trigger.type = \"balance\"`.\n"
                "4. If the action involves sending or paying, set `action.type = \"transfer\"`.\n"
                "5. If the action involves trading, set `action.type = \"swap\"`.\n"
                "6. Include the destination address if present.\n"
                "7. If a value is missing, leave the field empty (`\"\"`).\n"
                "8. Round all numbers to 4 decimal places.\n"
                "9. Always ensure JSON is syntactically valid and uses double quotes.\n\n"
                "---\n"
                "### 🔹 Example Inputs and Outputs\n\n"
                "**Input:**\n"
                "> When ETH price hits 3000, sell 0.1 ETH for USDC.\n\n"
                "**Output:**\n"
                "{\n"
                '  "trigger": {\n'
                '    "type": "price",\n'
                '    "asset": "ETH",\n'
                '    "operator": ">=",\n'
                '    "value": 3000\n'
                "  },\n"
                '  "action": {\n'
                '    "type": "swap",\n'
                '    "from_token": "ETH",\n'
                '    "to_token": "USDC",\n'
                '    "amount": 0.1,\n'
                '    "to": ""\n'
                "  }\n"
                "}\n\n"
                "---\n"
                "### MISSION\n"
                "You are the reasoning engine of the Kairos framework.  "
                "You do **not** respond conversationally.  "
                "You **convert human intent into structured onchain logic**."
            )
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