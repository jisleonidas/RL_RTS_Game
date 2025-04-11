import asyncio
import websockets
import json
from math import sqrt
# from agent_tf import RLPlant
from agent import RLPlant

import traceback

actions = ["moveN", "moveNE", "moveE", "moveS", "moveSW", "moveW", "moveNW", "chase0", "chase1", "chase2", "defend", "idle"]
n_observations = 260
n_actions = len(actions)

rlplants = []

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


def calc_distance(agent1, agent2):
    x_diff = agent1["global_position"]["x"] - agent2["global_position"]["x"]
    y_diff = agent1["global_position"]["y"] - agent2["global_position"]["y"]
    dist = sqrt(x_diff**2 + y_diff**2)
    return dist


async def process_state(websocket, id, data, prev_reward, prev_terminated, prev_truncated):
    if len(rlplants)-1 < id:
        # rlplants.append(RLPlant((n_observations,), n_actions))
        rlplants.append(RLPlant(n_observations, n_actions))
    # action = rlplants[id].run_agent(data_to_nn_input(data), prev_reward, prev_terminated, prev_truncated)
    action = int(rlplants[id].run_agent(data_to_nn_input(data), prev_reward, prev_terminated, prev_truncated)[0][0])

    dists = [99999999]
    print("Zero test")
    for i in range(len(data)):
        if not data[i]["null"]:
            dists.append(calc_distance(data[0], data[i]))
        else:
            dists.append(99999999)
    
    paired = list(zip(dists, data))
    paired.sort(key=lambda x: x[0])
    sorted_data = [d for _, d in paired]

    sorted_enemy_data = [i for i in sorted_data if not i["null"] and data[0]["friendly"] != i["friendly"]]

    action_command = {
        "id": id,
        "action": action,
        "chase0": sorted_enemy_data[0]["id"],
        "chase1": sorted_enemy_data[1]["id"],
        "chase2": sorted_enemy_data[2]["id"]
    }

    json_action_command = json.dumps(action_command)
    await websocket.send(json_action_command)

    print(f"Sent: {json_action_command}")


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
            await process_state(websocket, state["self"]["id"], state["data"], state["reward"], state["terminated"], state["truncated"])
        except Exception as e:
            print("Error:", e)
            traceback.print_exc()

async def main():
    async with websockets.serve(handler, "localhost", 8765):
        print("WebSocket server running on ws://localhost:8765")
        await asyncio.Future()  # Run forever

asyncio.run(main())

