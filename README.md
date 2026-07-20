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

## v1.6 changes

- Moving platforms now come in three motion types — horizontal (teal), vertical (purple), and circular (amber) — and appear earlier, more often, and longer into each stage
- Obstacles expanded from 5 to 8 silhouettes (added a thin spike, a wide low barrier, and a boulder cluster) and every obstacle now spawns at a randomized size, so routes no longer repeat identical shapes
- From Level 3 onward, some rows spawn a second obstacle on the opposite side of the platform for denser routes
- Added a MUSIC mute toggle: click/tap the on-screen button in the top-right, or press **M**
- Rebuilt the mobile controls as a floating joystick: touch anywhere on the left ~60% of the screen and that becomes the joystick center — no more hunting for a small fixed button. Tap the right side to jump; BOOST has its own button, bottom-right
- Fixed handheld orientation being set to "sensor" (which could rotate this landscape-only game into portrait and push the touch controls off the usable area) — it's now locked to landscape
- Enabled mouse-as-touch emulation in the project settings, so the mobile controls can be tested with a mouse directly in the Godot editor

## v1.7 changes

- Moving platform speed raised ~1.5x across the board, and the per-level speed increase is now steeper (was +0.12 per stage, now +0.22 per stage) so later stages feel noticeably faster, not just wider-traveling
- Regenerated the music from scratch (`tools/generate_music.js`): detuned triangle/saw pads and lead instead of bare sines, a real four-on-the-floor kick with backbeat snare and swung hats, sidechain "pump" ducking the pads/bass in time with the kick, a short delay-based reverb pass for depth, and a clearer 6-section arc (intro → build → groove → lead → breakdown → climax) instead of a flat loop. Re-run `node tools/generate_music.js` any time to regenerate `audio/terracast_garden_groove.wav`

## v1.8 changes

- Rebuilt the mobile joystick/jump/boost controls on top of Godot's `Control` + `_gui_input` pipeline instead of a raw `Node2D` + `_input` handler. The character-select buttons (which already worked on your phones) are standard Controls, so this puts the touch controls through the exact same proven input path rather than a separate lower-level one that may not have been receiving touch events at all on some exported builds
- Reordered UI construction so the character-select, stage-complete, and win screens are always layered above the touch controls and correctly take input priority over them while shown
- Added a desktop mouse fallback to the same handler, independent of the editor-only "emulate touch from mouse" setting
- If controls still don't appear after this, the next most likely cause is the export/build pipeline itself (Web export vs. native APK/IPA behave very differently for touch) rather than anything in this script

## v1.9 changes

- **Rescue boost is now free**, not coin-purchased: one charge is automatically banked every time a new 2,000 m stage checkpoint is reached (levels 2-8), stockpiling up to 7 charges over a flawless run. Charges persist through deaths/respawns and are only spent when you actually use one
- **Coins**: spawn rate doubled, and each coin is now worth a random 1-10 (bigger, brighter coins are worth more) instead of a flat 1
- **Coins are now permanent**: saved to `user://terracast_save.dat` and reloaded on every launch, so your total carries over between sessions instead of resetting each run
- **New Climber Store**: a STORE button on the character-select screen opens a shop with 4 new premium worms (Iridescent, Lava, Galaxy, Rainbow — 40/70/110/180 coins) alongside the original 6 free ones. Purchases are permanent and saved immediately
- Note on persistence: `user://` saves are per-browser/per-device for a Web export (Godot handles this via IndexedDB automatically) — there's no cross-device account system yet, so the same player on a different phone/browser starts fresh

## v2.0 changes

- New diagnostic info: on the reporter's phone, the character-select screen text/colors render fine, but every built-in `Button` was invisible. That specifically implicates Godot's built-in Button/Theme rendering on that export target, not layout math or the joystick logic
- Replaced every `Button` in the game (character select, mute, store, buy cards, stage-continue, climb-again) with a new hand-drawn `SimpleButton` class that paints its own background/border/text via `_draw()` and handles touch/mouse itself via `_gui_input()` — the same technique already proven to work for the joystick and for the game world's obstacles/platforms, with zero dependency on the engine's default Theme
- Also replaced the store's card background (`Panel`, another theme-dependent control) with a plain `ColorRect`
- If buttons still don't render after this, that would point at something even more fundamental in the export (e.g. the GUI CanvasLayer itself, or the renderer) — at that point the browser console output becomes essential to keep debugging blind

## v2.1 changes

- **Local profile / "login"**: a welcome screen now gates the game the first time it's played, requiring an age confirmation (13+), an email, and a username. This is explicitly **not** a real account system — no server, no verification email, no password. It's stored in the same local save file as coins/unlocks, purely so a returning player doesn't have to redo it. Real multiplayer/accounts need a backend (see the note in the previous section) and are not built yet
- Usernames are checked against a small blocklist to keep out real names/explicit terms; it's a basic local filter, not a moderation service
- **Local leaderboard**: a 🏆 LEADERBOARD button on the character-select screen shows the top 10 fastest full climbs (16,000 m) on this device, with name, time, and coins. A finished run is recorded automatically
- **Dynamic obstacle behavior**: from Level 3 onward, roughly one in three obstacles now actively behaves instead of sitting still — SWING (pendulums back and forth), ROTATE (spins continuously), or TELEGRAPH (idles, flashes a warning, then lunges sideways and back). These read as genuine hazards that reward watching and timing rather than pure reflexes
- Still to build (by your priority order): combo/streak system, then power-ups (shield/magnet/slow-fall)

## v2.2 changes

- **Combo/streak system**: coins collected within 4 seconds of each other chain into a streak (shown top-right); every 5th streak step pays an escalating bonus
- **Obstacles now matter**: touching one without a shield breaks your combo and knocks you back; with a shield, the hit is absorbed instead and the shield is consumed
- **Power-ups**: Shield, Magnet, and Slow-Fall pickups spawn once per level. Shield stacks up to 3, Magnet pulls nearby coins toward you for 8s, Slow-Fall softens gravity for 6s. Active effects shown in a HUD line
- **Character tiers**: COMMON/RARE/EPIC/LEGENDARY badges in the store, modeled on Gimkit Don't Look Down's large purchasable "Gims" roster bought from an Item Shop
- **Costumes**: a new COSTUMES tab in the store — Stripes, Spots, Sparkle Trail, Radiant Glow — purchasable and equippable on any character, drawn as an overlay on the character art itself

## v3.0 changes -- real character art from the TerraCast Universe sheet

- Replaced the entire playable roster with the user's own TerraCast Universe character-sheet artwork. `assets/characters/*.png` are cropped directly from the uploaded poster, with an automated background-removal pass (corner-color sampling + soft alpha falloff) so each character reads as a cutout sprite rather than a rectangle
- **Kid crew excluded on purpose** — per instruction, only bug/invertebrate characters were used. No images of the real children on the sheet were generated or used anywhere in the game
- **Roster (34 characters)**: Worm Crew (Wiggles, Ruby, Loam, Squig, Mo — free starters), Springtail Squad, Soil Mite Crew, Pill Bug Posse, BSFL Family, Beetle Brigade, and Visitor Friends (Beez, Butta, Hopper, Sneaky — Birdy was left out since a songbird isn't a bug), each carrying the poster's own names and one-line descriptions, priced up through the tier system from v2.2
- `Worm._draw()` now draws the real sprite (via `draw_texture_rect`, flipped for facing direction, squash/stretched the same way the old procedural body was) when a character has `sprite_texture` set, and falls back to the original hand-drawn worm otherwise -- so nothing breaks if a future character is added without art
- Character-select and the store's CLIMBERS tab now show real thumbnail art per character and are paginated (6 and 9 per page respectively), since 34 characters no longer fit on one screen
- **Known limitation, worth being upfront about**: the crops were cut automatically from a single static poster image using estimated grid coordinates, not manually verified one-by-one, and each character has only one static pose (no walk/run animation frames -- movement is the same transform-based squash/stretch/flip the old procedural worm used). Framing may be slightly off on some of the 34, and none of them animate limbs. If particular characters look wrong in-game, flag which ones and either send tighter individual crops or ask for a re-crop pass on just those
