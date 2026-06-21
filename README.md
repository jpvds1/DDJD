# Heaven Run

> *"Can you survive this deadly course or will you succumb to the trials imposed by the Gods?"*

**Heaven Run** is a high-intensity 3D parkour platformer set in a serene heavenly landscape riddled with deadly traps. You sprint, wall-run, and dash across disconnected platforms and towering walls, racing to reach the end of each gauntlet as fast as possible. The contrast between the calm, open-sky environment and the brutal hazards within it is intentional. Heaven Run is about speed, precision, and mastering every inch of movement.

Built with **Godot 4** as a university project for the *Design and Development of Digital Games* course - Team A.

---

## Core Concept

Heaven Run is built around the **time trial** loop: reach the end, see your time, try again faster. Every mechanic, from the responsive movement to the gear system, feeds back into that one goal.

---

## Game Loop

1. **Select a level** from the level menu
2. **Run** - traverse platforms, avoid hazards, hit checkpoints
3. **Finish** - your time is measured and converted into 1–3 stars
4. Stars are spent in the **loadout menu** to unlock gear items
5. Completing levels and challenges unlocks additional gear
6. **Equip gear** to boost your stats and chase better times
7. Submit your time to the **online leaderboard** and compete globally

In **Endless mode**, the loop is survival instead: procedurally assembled chunks stream in while your lives tick down; run until you die, beat your distance record.

---

## Movement

Heaven Run's movement system is the heart of the game. Every action is designed to chain into the next:

| Action | Input | Notes |
|---|---|---|
| Walk / Strafe | WASD | — |
| Sprint | Hold Shift | Higher top speed, faster acceleration |
| Jump | Space | Variable height; release early to cut the jump |
| Double / Extra Jump | Space (airborne) | 2 extra jumps by default |
| Wall Run | Automatic (near wall) | Run into a tagged wall while airborne and moving fast enough |
| Wall Jump | Space (while wall running) | Launches you away from and along the wall |
| Dash | Q | Forward burst; 1 charge, recharges on cooldown |
| Look | Mouse | First-to-third person zoom with scroll wheel |
| Pause | Escape | — |

### Movement details

- **Coyote time** - jump input is still accepted for a brief window after walking off a ledge
- **Jump buffering** - a jump pressed just before landing registers as soon as you touch the ground
- **Variable jump height** - releasing jump early multiplies upward velocity down, giving fine control over arc height
- **Wall run** - engages automatically when you approach a wall in the `wall_run` group with enough horizontal speed; gravity is damped for the first second, then the character slides down; wall jumping carries forward momentum and resets extra jumps
- **Dash** - a short high-speed forward burst (50 u/s); post-dash speed is capped to prevent runaway velocity; can be chained off wall runs
- **Camera** - smooth zoom in third person via scroll wheel; locks and tilts automatically during wall runs

---

## Levels

| Level | Description |
|---|---|
| Tutorial | Introduces movement mechanics one at a time with in-world prompts |
| Level 1 | Entry-level gauntlet, unlocks the Feathered Crown on completion |
| Level 2 | Faster-paced obstacles; unlocks the Wind-Weave Vest on completion |
| Level 3 | Smaller but more technical, with a high density of hazards |
| Endless | Procedurally assembled from pre-built chunks; 3 lives, distance-based scoring |

Each campaign level has:
- A **3-life system** - run out and the attempt ends
- **Checkpoints** - respawn in place instead of at the start
- **Star rating** based on completion time (thresholds vary per level)
- A **gear unlock** awarded on first completion
- **Ghost replay** - your best run plays back as a transparent character on subsequent attempts
- **Online score submission** (when signed in)

---

## Hazards

| Hazard | Behaviour |
|---|---|
| Spikes | Static instant-kill traps |
| Saw blades | Spinning or moving blades |
| Wrecking ball | Swinging pendulum |
| Laser | Beam that fires on a cycle |
| Lava | Contact-kill surface |
| Kill zone | Invisible boundary - fall off the platform and die |
| Boost ring | Not a hazard - launches the player at high speed in a set direction |

---

## Gear System

Gear provides **stat bonuses** that directly affect movement. There are three equipment slots, Head, Chest, and Boots, and three sets. Items are unlocked through level completion, star purchases, or achievements.

### Items

| Item | Slot | Set | How to Unlock | Bonuses |
|---|---|---|---|---|
| Racing Visor | Head | Quickstep | Buy (1 star) | +speed, +acceleration |
| Feathered Crown | Head | Aether | Complete Level 1 | +jump velocity |
| Infernal Horns | Head | Inferno | Achievement: *5 s airborne* | +dash cooldown reduction, −jump velocity |
| Wind-Weave Vest | Chest | Quickstep | Complete Level 2 | +speed, +acceleration |
| Seraph Mantle | Chest | Aether | Achievement: *500 m in Endless* | +jump velocity, −speed |
| Hellfire Harness | Chest | Inferno | Buy (1 star) | +dash cooldown reduction |
| Mercury Runners | Boots | Quickstep | Complete Tutorial | +speed, +acceleration |
| Gale Striders | Boots | Aether | Buy (1 star) | +jump velocity |
| Brimstone Treads | Boots | Inferno | Achievement: *no deaths* | +dash cooldown reduction |

### Sets

Equipping all three pieces of the same set activates a **set bonus** on top of the individual item bonuses:

| Set | Pieces | Set Bonus |
|---|---|---|
| **Quickstep** | Racing Visor + Wind-Weave Vest + Mercury Runners | +1.5 speed, +1.0 acceleration |
| **Aether** | Feathered Crown + Seraph Mantle + Gale Striders | +0.5 jump velocity, +1 extra jump |
| **Inferno** | Infernal Horns + Hellfire Harness + Brimstone Treads | +0.2 dash cooldown reduction, +1 extra dash |

Only one set bonus is active at a time, you must have all 3 pieces of the same set equipped.

---

## Achievements

| ID | Condition | Reward |
|---|---|---|
| `air_time_5s` | Stay airborne for 5 consecutive seconds | Infernal Horns |
| `no_extra_jumps` | Complete a level without using extra jumps | — |
| `no_deaths` | Complete a level without dying | Brimstone Treads |
| `endless_500m` | Reach 500 m in Endless mode | Seraph Mantle |

---

## Online Features

Heaven Run integrates with **Supabase** for authentication and leaderboards. Sign in with an account to:
- Submit your completion times after finishing a level
- View and filter the global leaderboard by level
- See your personal best alongside the top scores

Playing offline still saves everything locally: times, stars, gear, and achievements persist in `user://player_progress.json`.

---

## How to Run

1. Install [Godot 4](https://godotengine.org/download)
2. Clone or download this repository
3. Open Godot, click **Import**, and select `platformer-game/project.godot`
4. Press **F5** (or the Play button) to launch

---

## Authors

| Name | Institution | Team |
|---|---| ---|
| João Dias da Silva | Faculty of Engineering, University of Porto (FEUP) | Dev |
| Luís Miguel Arruda | Faculty of Engineering, University of Porto (FEUP) | Dev |
| Pedro Rojas Izquierdo | Faculty of Engineering, University of Porto (FEUP) | Dev |
| Tomás Sucena Lopes | Faculty of Engineering, University of Porto (FEUP) | Dev |
| Sofia Santos | School of Media Arts and Design (ESMAD) | 3D |
| Basil Gonçalves | School of Media Arts and Design (ESMAD) | 3D |
| Vincente Cardoso | Faculty of Engineering, University of Porto (FEUP) | Sound |
| Gonçalo Carvalho | Faculty of Engineering, University of Porto (FEUP) | Sound |


---
*“The sky awaits. Can you beat the record?”*



