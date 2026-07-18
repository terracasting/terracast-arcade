# TerraCast: Don't Dig Down — Playable Iteration 1.1

Open `project.godot` with Godot 4.3 or newer and press **F6/F5** to play.

## Controls

- **A/D** or **Left/Right arrows:** Move and steer in the air
- **Space**, **W**, or **Up arrow:** High jump (hold for maximum height)
- **Q** or **Shift:** Rescue Boost while falling after reaching Level 2
- **R:** Return to the most recently saved level checkpoint

## Included in this iteration

- High, variable-height jump with generous coyote time and jump buffering
- Smooth camera that follows long vertical and horizontal routes
- Eight extra-long biomes with 50 climbing steps each across a 7,000-pixel-wide weaving course
- 400 main route platforms, plus checkpoint platforms, the ground floor, and finish area
- High first jump plus a slightly lower mid-air double jump
- Full-width ground floor that catches falls at the bottom
- Permanent checkpoint at the beginning of every level
- Level 2 Rescue Boost that carries the worm about ten platform rows upward
- Air steering during the rescue so the player must still find a safe landing
- Two-minute original multi-section instrumental with drums, bass, chords, rhythm and lead
- Six platform materials: soil ledges, leaves, mushrooms, bark, stones, and wood
- Solid stones, stumps, tall mushrooms, roots, and plant obstacles placed throughout routes
- Rebalanced route spacing so Rescue Boost is optional rather than required
- One-way platform collision: jump upward through ledges and land safely on top
- Automated validation for all 400 route jumps and seven level transitions
- Repeating authored challenge rooms: tiny staircases, precision crossings, obstacle gauntlets, and recovery ledges
- Difficulty-scaled mandatory double-jump tests with no instructional labels
- Removed all challenge instruction labels from the playfield
- Character-selection screen with six named worms and distinct visual accessories
- Eight 2,000-meter stages for a 16,000-meter total climb
- Difficulty progression: Easy, Normal, Hard, Super Hard, Extra Hard, Crazy Hard, Impossible, NO WAY BRUH
- A fresh Rescue Boost is awarded at each new stage checkpoint
- Summit completion platform and full YOU WON screen with replay button
- Biome-specific background scenery: tunnel lights, fungal groves, leaves, pond droplets, greenhouse growth, and sunflower glow
- Every 2,000-meter stage now contains 100 route platforms instead of 50
- Full-screen stage-complete transition between all eight stages
- Each new stage resets its visible height counter to 0 / 2,000 meters
- HUD separately tracks stage height and total 16,000-meter campaign height
- Completely rebuilt cohesive landing-pad art with rounded layered silhouettes, consistent highlights, shadows, and material marks
- Moving platforms begin in Hard and become more frequent, faster, and wider-traveling in later stages
- Later-stage routes add progressively stronger secondary weaving while preserving safe checkpoint alignment
- Rounded cohesive obstacle art replaces angular rocks, stumps, mushrooms, logs, and plants
- Moving platforms begin halfway through Stage 1 with gentle movement and use one consistent teal-blue material
- Visible coin counter; every collected gold coin is tracked
- Press B after using a Rescue Boost to purchase an extra boost for 20 coins
- Procedural placeholder worm, platforms, coins, soil layers, roots, lighting, and HUD

The rescue is restored when a new checkpoint is reached or after respawning at an unlocked checkpoint. This iteration is intended to tune movement and scale before final character animation and production artwork are installed.
