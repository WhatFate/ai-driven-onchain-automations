import json

def parse_and_extract_ai_response(response: str) -> dict:
    try:
        data = parse_ai_response(response)
        workflow = extract_workflow(data)
        return {
            "success": True,
            "type": data.get("type", "automation_json"),
            "workflow": workflow,
            "prompt": data.get("prompt")
        }
    except json.JSONDecodeError:
        return {
            "success": False,
            "type": "text",
            "message": response.strip()
        }
    except Exception as e:
        return {
            "success": False,
            "type": "text",
            "message": f"Unexpected error: {str(e)}"
        }


def parse_ai_response(response: str) -> dict:
    data = json.loads(response)

    trigger = data.get("trigger", {})
    action = data.get("action", {})

    prompt = f"""Please review your automation action carefully before signing the transaction.

Trigger:
- Type: {trigger.get('type')}
- Asset: {trigger.get('asset')}
- is Greater Than: {trigger.get('isGreaterThan')}
- Value: {trigger.get('value')}

Action:
- Type: {action.get('type')}
- Token Address: {action.get('tokenAddress')}
- Amount: {action.get('amount')}
- Recipient Address: {action.get('recipient')}

Verify before signing. Mistakes may cause irreversible loss.

If everything looks correct, you can proceed to sign the transaction.
If anything is wrong, cancel and update the automation before signing.
    """

    return {"type": "automation_json", "data": data, "prompt": prompt}


def extract_workflow(data: dict) -> dict:
    trigger = data.get("data", data).get("trigger", {})
    action = data.get("data", data).get("action", {})
    print(data)
    return {
        "trigger_type": trigger.get("type"),
        "trigger_asset": trigger.get("asset"),
        "trigger_is_greater_than": trigger.get("isGreaterThan"),
        "trigger_value": trigger.get("value"),

        "action_type": action.get("type"),
        "action_token_address": trigger.get("tokenAddress"),
        "action_amount": action.get("amount"),
        "action_recipient": action.get("recipient"),
    }
