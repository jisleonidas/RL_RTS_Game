import asyncio
import websockets
import json

async def send_actions(websocket, data):
    action = "attack1"
    json_action = json.dumps(action)
    await websocket.send(json_action)
    print(f"Sent: {json_action}")

async def handler(websocket):
    print("WebSocket connection established")
    async for message in websocket:
        try:
            state = json.loads(message)
            print("Received agent state:")
            print("Timestamp:", state["timestamp"])
            for agent in state["data"]:
                # if not agent["null"]:
                #     print("No agent!")
                #     continue
                print(f"  ID: {agent['id']}")
                print(f"  Type: {agent['type']}")
                print(f"  Health: {agent['health']}")
                print(f"  Friendly: {agent['friendly']}")
                pos = agent["global_position"]
                print(f"  Position: ({pos['x']}, {pos['y']})")
                print()
            # await send_actions(websocket, state["data"])
        except Exception as e:
            print("Error:", e)

async def main():
    async with websockets.serve(handler, "localhost", 8765):
        print("WebSocket server running on ws://localhost:8765")
        await asyncio.Future()  # Run forever

asyncio.run(main())

