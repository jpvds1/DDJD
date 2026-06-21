# ☁️ Heaven Run

**Heaven Run** is a fast-paced, high-octane time-attack platformer where optimizing momentum is the key to achieving the best times. Set in a serene heavenly landscape, players must navigate through disconnected platforms, deadly traps, and high-speed gauntlets to reach the finish line as fast as possible. 

The catch? The global timer **never** stops. Every mistake costs you time. Can you survive the trials imposed by the Gods and climb to the top of the global leaderboard?

---

## 🚀 Unique Selling Proposition (USP)
A familiar time-trial racing concept combined with fluid parkour movement, emphasizing competitive score-chasing and a striking contrast between a serene heavenly environment and violent, gruesome hazards.

## 🎮 Core Movement Kit
The game features a highly responsive 3D character controller tailored to reward precise routing and quick reaction times:
* **Instant Acceleration:** No sluggish wind-up; reach max base speed instantly.
* **Sprint & Over-capping:** Push beyond base limits manually or via external boosters.
* **Triple Jump:** Ground jump + 2 airborne jumps. Each airborne jump completely resets your downward fall momentum. (Note: No Coyote Time!).
* **Natural Dash:** A massive, on-demand instantaneous velocity spike forward.
* **Infinite Wallrun:** Automatically triggered on designated surfaces. Chain them infinitely!
* **Dash Rings:** Environmental boosters that hook and launch you at maximum speed.

## ☠️ The Golden Rule & Hazards
**One hit = Instant Death.** Hitting a hazard or falling into the void instantly teleports you back to the last active checkpoint. However, **the global speedrun timer never stops**.

Beware of the environment:
* 🔨 **Wrecking Balls:** Massive pendulums demanding perfect timing.
* ⚠️ **Proximity Spears:** Hidden spike traps that trigger upon close approach.
* ⚡ **Laser Barriers:** High-tech beams cycling on fixed timers.
* ⚙️ **Buzzsaws:** Static, spinning death zones.
* 🌋 **Lava & Pits:** Immediate death zones.

## 🗺️ Game Modes & Levels
All levels are completely unlocked from the start. Your goal is not just to finish, but to master the time.
* **Tutorial:** Direct onboarding testing basic inputs and spatial hazard awareness.
* **Level 1:** Choice-based paths branching between Precision vs. Flow routes.
* **Level 2:** The chaotic Gauntlet emphasizing chained wallruns and strict momentum management.
* **Level 3:** The Speedrunner's Sandbox, packed with hidden shortcuts for advanced players.
* **Level 4:** "The Ultimate Gauntlet" - A long, brutal endurance test combining split-second routing decisions and every hazard available.
* **Level 5:** "Absolute Control" - An extreme-difficulty exam testing your absolute mastery over acceleration and mid-air adjustments.
* **Endless Mode:** No finish line, just survival. Track your total meters covered and climb the distance leaderboard!

## 🛠️ Technical Specs
* **Engine:** Built with [Godot Engine v4.x](https://godotengine.org/). Physics handled via `CharacterBody3D` with Continuous Collision Detection (CCD) to prevent high-speed tunneling.
* **Database & Leaderboards:** Powered by [Supabase](https://supabase.com/). 
* **Authentication:** Integrated Google OAuth to securely track and store official leaderboard high scores. Protected by Supabase Row Level Security (RLS).
* **Target Platform:** PC (Keyboard & Mouse).

## 🎧 Audio & Sound Design
* Pitch-shifting dash audio that scales with the player's current velocity.
* Full 3D spatial audio to track incoming lasers, saws, and wrecking balls.
* Acoustic ducking: The high-tempo synth-wave BGM dynamically lowers its volume upon death, emphasizing the impact of your mistakes.

**Authors:**

| Name |
|---|
| Pedro Rojas Izquierdo |
| João Pacheco Veiga Dias da Silva |
| Luís Miguel Melo Arruda |
| Tomás de Campos Sucena de Sequeiros Lopes |

---
*“The sky awaits. Can you beat the record?”*



