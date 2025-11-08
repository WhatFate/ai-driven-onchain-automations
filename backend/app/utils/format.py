import json

def parse_and_extract_ai_response(response: str) -> dict:
    data = parse_ai_response(response)
    workflow = extract_workflow(data)
    return workflow


def parse_ai_response(response: str) -> dict:
    try:
        data = json.loads(response)
    except json.JSONDecodeError:
        raise ValueError("AI returned invalid JSON")
    
    if not isinstance(data, dict):
        raise ValueError("AI response is not a JSON object")
    if "trigger" not in data or "action" not in data:
        raise ValueError("Missing 'trigger' or 'action' in AI response")
    
    return data
    
def extract_workflow(data: dict) -> dict:
    trigger = data.get("trigger", {})
    action = data.get("action", {})

    return {
        "trigger_type": trigger.get("type"),
        "trigger_asset": trigger.get("asset"),
        "trigger_operator": trigger.get("operator"),
        "trigger_value": trigger.get("value"),
        "action_type": action.get("type"),
        "action_token": action.get("token"),
        "action_amount": action.get("amount"),
        "action_to": action.get("to"),
    }