import asyncio
import websockets
import json

async def handler(websocket):
    print("WebSocket connection established")
    async for message in websocket:
        try:
            state = json.loads(message)
            print("Received agent state:")
            print("Timestamp:", state["timestamp"])
            for agent in state["data"]:
                print(f"  ID: {agent['id']}")
                print(f"  Type: {agent['type']}")
                print(f"  Health: {agent['health']}")
                print(f"  Friendly: {agent['friendly']}")
                pos = agent["global_position"]
                print(f"  Position: ({pos['x']}, {pos['y']})")
                print()
        except Exception as e:
            print("Error:", e)

async def main():
    async with websockets.serve(handler, "localhost", 8765):
        print("WebSocket server running on ws://localhost:8765")
        await asyncio.Future()  # Run forever

asyncio.run(main())

