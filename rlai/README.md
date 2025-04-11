# Actions:

## Movement
Move N, NE, E, SE, S, SW, W, NW

## Chase
Chase 0, Chase 1, Chase 2  -- number indicates closeness of enemy unit from the current unit

## Defend

## Idle


# Reward:

+10 - Enemy kill
+1 - Enemy damage
-1 - Friendly damage
-10 - Friendly death

Input to neural network:

type:
    swordsman   100
    knights     010
    archers     001
health: 0 - 100 (normalized to 0 to 1)
friendly: true or false
state:
    idle    100000
    walk    010000
    run     001000
    chase   000100
    attack  000010
    defend  000001
position_x: 0 to 1000 (normalized)
position_y: 0 to 1000 (normalized)

total features per agent: 13
total agents in total: 20
total input neurons: 20 * 13 = 260