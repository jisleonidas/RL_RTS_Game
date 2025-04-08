import asyncio
import websockets
import json
from agent import RLPlant

actions = ["moveN", "moveNE", "moveE", "moveS", "moveSW", "moveW", "moveNW", "chase1", "chase2", "chase3", "defend", "idle"]
n_observations = 260
n_actions = len(actions)

rlplant = RLPlant(n_observations, n_actions)

type_map = {"swordsman": 0, "knight": 1, "archer": 2}
state_map = {"idle": 0, "walk": 1, "run": 2, "chase": 3, "attack": 4, "defend": 5}

def one_hot(index, num_classes):
    vec = [0] * num_classes
    vec[index] = 1
    return vec

def data_to_nn_input(data):
    state = [] 
    count = 0

    print(data)

    for i in data:
        state.extend(one_hot(type_map[i["type"]], len(type_map)))
        state.append(i["health"]/100)
        state.append(i["friendly"])
        state.extend(one_hot(state_map[i["state"]], len(state_map)))
        state.append(i["global_position"]["x"]/1000)
        state.append(i["global_position"]["y"]/1000)
        count += 1
    
    while (count < 20):
        state.extend([-1]*13)
        count += 1
    
    return state


async def process_state(websocket, data, prev_reward, prev_terminated, prev_truncated):
    action = int(rlplant.run_agent(data_to_nn_input(data), prev_reward, prev_terminated, prev_truncated)[0][0])

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
            await process_state(websocket, state["data"], state["reward"], state["terminated"], state["truncated"])
        except Exception as e:
            print("Error:", e)

async def main():
    async with websockets.serve(handler, "localhost", 8765):
        print("WebSocket server running on ws://localhost:8765")
        await asyncio.Future()  # Run forever

asyncio.run(main())

