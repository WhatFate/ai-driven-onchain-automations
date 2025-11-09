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
- Operator: {trigger.get('operator')}
- Value: {trigger.get('value')}
- Interval: {trigger.get('interval') if trigger.get('type') == "time" else "N/A"}
- Chain: {trigger.get('chain') or 'default'}

Action:
- Type: {action.get('type')}
- From Token: {action.get('from_token')}
- To Token: {action.get('to_token') or 'N/A'}
- Amount: {action.get('amount')}
- Recipient Address: {action.get('to') or 'N/A'}
- Protocol: {action.get('protocol') or 'N/A'}

Verify before signing. Mistakes may cause irreversible loss.

If everything looks correct, you can proceed to sign the transaction.
If anything is wrong, cancel and update the automation before signing.
    """

    return {"type": "automation_json", "data": data, "prompt": prompt}


def extract_workflow(data: dict) -> dict:
    trigger = data.get("data", data).get("trigger", {})
    action = data.get("data", data).get("action", {})

    return {
        "trigger_type": trigger.get("type"),
        "trigger_asset": trigger.get("asset"),
        "trigger_operator": trigger.get("operator"),
        "trigger_value": trigger.get("value"),
        "trigger_interval": trigger.get("interval") if trigger.get("type") == "time" else None,
        "trigger_chain": trigger.get("chain"),
        "action_type": action.get("type"),
        "action_from_token": action.get("from_token"),
        "action_to_token": action.get("to_token"),
        "action_amount": action.get("amount"),
        "action_to": action.get("to"),
        "action_protocol": action.get("protocol"),
    }
