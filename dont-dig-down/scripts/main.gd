extends Node2D

const VIEW := Vector2(1920, 1080)
const WORLD_WIDTH := 7000.0
const LEVEL_HEIGHT := 19200.0
const LEVELS := 8
const WORLD_BOTTOM := 920.0

var player: CharacterBody2D
var camera: Camera2D
var checkpoint := Vector2(3500, 800)
var checkpoint_level := 1
var rescue_charges := 0
var combo_streak := 0
var combo_timer := 0.0
const COMBO_WINDOW := 4.0
var combo_label: Label
var shield_charges := 0
var magnet_timer := 0.0
var slowfall_timer := 0.0
var obstacle_hit_cooldown := 0.0
const MAGNET_DURATION := 8.0
const MAGNET_RADIUS := 260.0
const SLOWFALL_DURATION := 6.0
const DEFAULT_GRAVITY := 1750.0
var powerup_label: Label
var rescue_active := false
var rescue_start_y := 0.0
var rescue_target_y := 0.0
var best_height := 0.0
var status_text := "LEVEL 1 CHECKPOINT SAVED"
var status_timer := 4.0
var ability_label: Label
var status_label: Label
var level_label: Label
var height_label: Label
var coin_label: Label
var hint_label: Label
var rescue_button: Control
var mobile_controls: MobileControls
var character_menu: ColorRect
var character_list_box: Control
var char_page := 0
const CHAR_PAGE_SIZE := 6
var store_overlay: ColorRect
var store_list_box: Control
var store_coin_label: Label
var store_tab := "characters"
var store_char_page := 0
const STORE_PAGE_SIZE := 9
var win_overlay: ColorRect
var stage_overlay: ColorRect
var stage_overlay_title: Label
var stage_overlay_detail: Label
var login_screen: ColorRect
var email_field: LineEdit
var username_field: LineEdit
var age_toggle: SimpleButton
var login_error_label: Label
var age_confirmed := false
var player_email := ""
var player_username := ""
var leaderboard: Array = []
var leaderboard_overlay: ColorRect
var leaderboard_list_box: Control
var run_start_time := 0.0
# A short, generic blocklist so usernames can't be real/explicit names. Not
# exhaustive -- a real product would use a moderation service -- but enough
# to stop the obvious cases for a local-only profile.
const BLOCKED_WORDS := [
	"fuck","shit","bitch","cunt","nigger","nigga","fag","rape","porn","penis","vagina",
	"nazi","whore","slut","admin","moderator","sex","dick","cock","asshole","retard",
]
var game_started := false
var won := false
var coins := 0
var unlocked_variants: Array[int] = []
const SAVE_PATH := "user://terracast_save.dat"
const TIER_COLORS := {
	"COMMON": Color("9aa39a"), "RARE": Color("6fb7e0"),
	"EPIC": Color("b57de8"), "LEGENDARY": Color("f2c94c"),
}
# Six free climbers plus four store-only ones, unlocked permanently with
# saved-up coins. Coins and unlocks persist across sessions via SAVE_PATH.
# Tiers follow Gimkit's Item Shop-style rarity structure (Don't Look Down
# uses a large purchasable roster of "Gims" bought with GimBucks): more
# common climbers are free, higher tiers cost more and stand out visually.
# The TerraCast Universe bug crew, cropped from the user's own character-sheet
# artwork (assets/characters/*.png) and background-removed. The Worm Crew
# is the free starter roster; every other crew is a purchasable tier, mirroring
# Gimkit Don't Look Down's large purchasable "Gims" roster bought with GimBucks.
const CHARACTERS := [
	{"name": "WIGGLES", "sprite": "worm_wiggles.png", "color": Color("b49380"), "price": 0, "tier": "COMMON", "blurb": "The cheerful red wiggler. Everyone's favorite guide!"},
	{"name": "RUBY", "sprite": "worm_ruby.png", "color": Color("bca190"), "price": 0, "tier": "COMMON", "blurb": "Strong and smart. Keeps the soil moving."},
	{"name": "LOAM", "sprite": "worm_loam.png", "color": Color("76563c"), "price": 0, "tier": "COMMON", "blurb": "Quiet and steady. Loves rich, dark soil."},
	{"name": "SQUIG", "sprite": "worm_squig.png", "color": Color("956e5b"), "price": 0, "tier": "COMMON", "blurb": "Curious and quick. Always wiggling!"},
	{"name": "MO", "sprite": "worm_mo.png", "color": Color("6d5c5b"), "price": 0, "tier": "COMMON", "blurb": "Shy but helpful. Works deep underground."},
	{"name": "SPRINGO", "sprite": "springtail_springo.png", "color": Color("c4bbad"), "price": 15, "tier": "COMMON", "blurb": "The leader. Jumps high!"},
	{"name": "BOUNCE", "sprite": "springtail_bounce.png", "color": Color("8a8074"), "price": 18, "tier": "COMMON", "blurb": "Loves to bounce."},
	{"name": "PIXIE", "sprite": "springtail_pixie.png", "color": Color("938e87"), "price": 20, "tier": "COMMON", "blurb": "Super tiny and quick."},
	{"name": "FROST", "sprite": "springtail_frost.png", "color": Color("8d7e69"), "price": 22, "tier": "COMMON", "blurb": "Cold-weather expert."},
	{"name": "MITZI", "sprite": "soilmite_mitzi.png", "color": Color("d5bba7"), "price": 30, "tier": "RARE", "blurb": "Red and busy. Breaks down organic matter."},
	{"name": "MILO", "sprite": "soilmite_milo.png", "color": Color("af936b"), "price": 32, "tier": "RARE", "blurb": "Pale and quick. Eats fungi."},
	{"name": "DUSTY", "sprite": "soilmite_dusty.png", "color": Color("cec3b3"), "price": 35, "tier": "RARE", "blurb": "Lives in dry leaves and litter."},
	{"name": "SPRITZ", "sprite": "soilmite_spritz.png", "color": Color("dbcebb"), "price": 38, "tier": "RARE", "blurb": "Moisture lover. Helps with decay."},
	{"name": "SHELLY", "sprite": "pillbug_shelly.png", "color": Color("665b4d"), "price": 42, "tier": "RARE", "blurb": "The leader. Tough shell, soft heart."},
	{"name": "ROLLY", "sprite": "pillbug_rolly.png", "color": Color("65594c"), "price": 45, "tier": "RARE", "blurb": "Always rolling and chilling."},
	{"name": "PEBBLE", "sprite": "pillbug_pebble.png", "color": Color("a2988a"), "price": 48, "tier": "RARE", "blurb": "Little and cute. Loves moist places."},
	{"name": "DASH", "sprite": "pillbug_dash.png", "color": Color("7b7063"), "price": 50, "tier": "RARE", "blurb": "Fast crawler and sneak expert."},
	{"name": "TANK", "sprite": "pillbug_tank.png", "color": Color("b4ac9d"), "price": 55, "tier": "RARE", "blurb": "Strong and solid. Protects the crew."},
	{"name": "BUSTER", "sprite": "bsfl_buster.png", "color": Color("6d604e"), "price": 60, "tier": "EPIC", "blurb": "Black Soldier Fly. Lays eggs and starts the cycle."},
	{"name": "DOTS", "sprite": "bsfl_dots.png", "color": Color("d1c8b4"), "price": 65, "tier": "EPIC", "blurb": "Just hatched! Tiny but mighty."},
	{"name": "NIBS", "sprite": "bsfl_nibs.png", "color": Color("e7decc"), "price": 68, "tier": "EPIC", "blurb": "Small appetite, big goals."},
	{"name": "CHOMPS", "sprite": "bsfl_chomps.png", "color": Color("b49f7b"), "price": 70, "tier": "EPIC", "blurb": "Always hungry, always growing."},
	{"name": "MUNCH", "sprite": "bsfl_munch.png", "color": Color("b59b71"), "price": 75, "tier": "EPIC", "blurb": "Getting bigger and stronger!"},
	{"name": "CRUNCH", "sprite": "bsfl_crunch.png", "color": Color("ba9e73"), "price": 80, "tier": "EPIC", "blurb": "Almost ready to pupate!"},
	{"name": "MAX", "sprite": "bsfl_max.png", "color": Color("e6d8c1"), "price": 85, "tier": "EPIC", "blurb": "Big and busy. Time to transform!"},
	{"name": "SKY", "sprite": "bsfl_sky.png", "color": Color("71614d"), "price": 95, "tier": "EPIC", "blurb": "Black Soldier Fly. Spreads pollen and starts the cycle again."},
	{"name": "DUNA", "sprite": "beetle_duna.png", "color": Color("6a665b"), "price": 90, "tier": "EPIC", "blurb": "Dung beetle. Rolls it, buries it, keeps the earth clean."},
	{"name": "BEET", "sprite": "beetle_beet.png", "color": Color("8d7465"), "price": 95, "tier": "EPIC", "blurb": "Ground beetle. Fast and fearless."},
	{"name": "LADY", "sprite": "beetle_lady.png", "color": Color("b8ac9b"), "price": 100, "tier": "EPIC", "blurb": "Ladybug. Loves to eat aphids."},
	{"name": "LONGO", "sprite": "beetle_longo.png", "color": Color("f0e6d5"), "price": 110, "tier": "EPIC", "blurb": "Longhorn beetle. Big explorer."},
	{"name": "BEEZ", "sprite": "visitor_beez.png", "color": Color("72573b"), "price": 140, "tier": "LEGENDARY", "blurb": "Busy pollinator, welcome guest."},
	{"name": "BUTTA", "sprite": "visitor_butta.png", "color": Color("7b6747"), "price": 150, "tier": "LEGENDARY", "blurb": "Beautiful butterfly."},
	{"name": "HOPPER", "sprite": "visitor_hopper.png", "color": Color("817745"), "price": 165, "tier": "LEGENDARY", "blurb": "Grasshopper. Big jumper!"},
	{"name": "SNEAKY", "sprite": "visitor_sneaky.png", "color": Color("cdc4ab"), "price": 180, "tier": "LEGENDARY", "blurb": "Praying mantis. Patient hunter."},
]
# Cosmetic-only patterns, purchasable separately and equippable on any
# unlocked climber -- the "costumes" layer on top of the character roster.
const COSTUMES := [
	{"name": "NO COSTUME", "pattern": 0, "price": 0, "tier": "COMMON"},
	{"name": "STRIPES", "pattern": 1, "price": 25, "tier": "COMMON"},
	{"name": "SPOTS", "pattern": 2, "price": 25, "tier": "COMMON"},
	{"name": "SPARKLE TRAIL", "pattern": 3, "price": 60, "tier": "RARE"},
	{"name": "RADIANT GLOW", "pattern": 4, "price": 100, "tier": "EPIC"},
]
var unlocked_costumes: Array[int] = [0]
var selected_costume := 0
var checkpoint_markers: Array[Area2D] = []
var rng := RandomNumberGenerator.new()
var music_player: AudioStreamPlayer
var muted := false
var mute_button: SimpleButton

class Worm extends CharacterBody2D:
	var gravity := 1750.0
	var jump_velocity := -1040.0
	var speed := 520.0
	var accel := 3000.0
	var air_accel := 1900.0
	var coyote := 0.0
	var jump_buffer := 0.0
	var squash := 0.0
	var facing := 1.0
	var boosting := false
	var jumps_used := 0
	var body_color := Color("d95745")
	var character_variant := 0
	var costume := 0 # 0=none, 1=stripes, 2=spots, 3=sparkle, 4=glow
	var sprite_texture: Texture2D = null

	func _ready() -> void:
		var shape := CapsuleShape2D.new()
		shape.radius = 25.0
		shape.height = 76.0
		var collider := CollisionShape2D.new()
		collider.shape = shape
		collider.position = Vector2(0, 4)
		add_child(collider)
		queue_redraw()

	func _physics_process(delta: float) -> void:
		var axis: float = Input.get_axis("move_left", "move_right")
		if abs(axis) > 0.05:
			facing = sign(axis)
		var target: float = axis * speed
		velocity.x = move_toward(velocity.x, target, (accel if is_on_floor() else air_accel) * delta)
		if is_on_floor():
			coyote = 0.13
			jumps_used = 0
		else:
			coyote -= delta
		if Input.is_action_just_pressed("jump"):
			jump_buffer = 0.14
		else:
			jump_buffer -= delta
		if jump_buffer > 0.0 and (coyote > 0.0 or jumps_used < 2):
			velocity.y = jump_velocity if coyote > 0.0 else -900.0
			jump_buffer = 0.0
			coyote = 0.0
			jumps_used += 1
			squash = 1.0
		if Input.is_action_just_released("jump") and velocity.y < -330.0 and not boosting:
			velocity.y *= 0.62
		if not boosting:
			velocity.y += gravity * delta
		move_and_slide()
		squash = move_toward(squash, 0.0, delta * 3.8)
		queue_redraw()

	func _draw() -> void:
		# Soft shadow under either the sprite or the procedural fallback.
		_draw_soft_ellipse(Vector2(0, 39), Vector2(35, 10), Color(0, 0, 0, 0.28))
		var stretch: float = 1.0 + minf(absf(velocity.y) / 2100.0, 0.18) - squash * 0.12
		if sprite_texture != null:
			_draw_sprite_character(stretch)
		else:
			_draw_procedural_worm(stretch)
		if boosting:
			var glow := Color(0.58, 1.0, 0.42, 0.72)
			var wing_l := PackedVector2Array([Vector2(-13,-15),Vector2(-68,-54),Vector2(-56,4),Vector2(-12,11)])
			var wing_r := PackedVector2Array([Vector2(13,-15),Vector2(68,-54),Vector2(56,4),Vector2(12,11)])
			draw_colored_polygon(wing_l, glow)
			draw_colored_polygon(wing_r, glow)
			draw_polyline(wing_l, Color("eaffbb"), 3.0)
			draw_polyline(wing_r, Color("eaffbb"), 3.0)

	func _draw_sprite_character(stretch: float) -> void:
		# Real cropped character art (TerraCast Universe roster) drawn as a
		# flat billboard with the same squash/stretch/costume treatment the
		# procedural worm used, so it reads consistently during play.
		var w := 96.0
		var h := 132.0 * stretch
		var top := -h + 34.0
		if costume == 4: # Glow costume: soft aura drawn behind the sprite
			draw_arc(Vector2(0, top + h * 0.5), 58, 0, TAU, 40, Color(body_color.r, body_color.g, body_color.b, 0.30), 16.0)
		var rect: Rect2
		if facing >= 0.0:
			rect = Rect2(Vector2(-w / 2.0, top), Vector2(w, h))
		else:
			rect = Rect2(Vector2(w / 2.0, top), Vector2(-w, h))
		draw_texture_rect(sprite_texture, rect, false)
		if costume == 1: # Stripes
			for frac in [0.35, 0.55, 0.75]:
				var y: float = top + h * frac
				draw_line(Vector2(-w * 0.4, y - 5), Vector2(w * 0.4, y + 5), Color(1, 1, 1, 0.5), 4.0)
		elif costume == 2: # Spots
			for frac in [0.3, 0.5, 0.7]:
				var y: float = top + h * frac
				draw_circle(Vector2(-w * 0.18, y), 3.4, Color(1, 1, 1, 0.55))
				draw_circle(Vector2(w * 0.2, y - 4), 2.8, Color(1, 1, 1, 0.45))
		elif costume == 3: # Sparkle
			for frac in [0.25, 0.5, 0.75]:
				var y: float = top + h * frac
				_draw_sparkle(Vector2((w * 0.28) * (1.0 if int(frac * 100) % 2 == 0 else -1.0), y))

	func _draw_procedural_worm(stretch: float) -> void:
		# Original hand-drawn worm, kept as a fallback for any variant without
		# real sprite art assigned.
		if costume == 4: # Glow costume: soft aura drawn behind the body
			draw_arc(Vector2(0, 8), 48, 0, TAU, 40, Color(body_color.r, body_color.g, body_color.b, 0.32), 14.0)
		for i in range(5, -1, -1):
			var y: float = 28.0 - i * 13.0 * stretch
			var radius: float = 20.0 - absi(i - 3) * 1.25
			var c: Color = body_color.lerp(Color.WHITE, 0.10 + float(i) / 20.0)
			draw_circle(Vector2(0, y), radius, c)
			draw_arc(Vector2(0, y), radius - 2, 0, TAU, 28, Color(0.35, 0.07, 0.035, 0.32), 2.0)
		if costume == 1: # Stripes
			for i in [1, 3, 5]:
				var y: float = 28.0 - i * 13.0 * stretch
				draw_line(Vector2(-15, y - 7), Vector2(15, y + 7), Color(1, 1, 1, 0.55), 4.0)
		elif costume == 2: # Spots
			for i in [0, 2, 4]:
				var y: float = 28.0 - i * 13.0 * stretch
				draw_circle(Vector2(-6, y), 3.4, Color(1, 1, 1, 0.6))
				draw_circle(Vector2(7, y - 4), 2.8, Color(1, 1, 1, 0.5))
		elif costume == 3: # Sparkle
			for i in [0, 2, 4]:
				var y: float = 28.0 - i * 13.0 * stretch
				var sx: float = 9.0 if i % 4 == 0 else -9.0
				_draw_sparkle(Vector2(sx, y - 3))
		# Face.
		draw_circle(Vector2(-8, -35), 6.2, Color.WHITE)
		draw_circle(Vector2(8, -35), 6.2, Color.WHITE)
		draw_circle(Vector2(-7 + facing * 1.5, -34), 2.5, Color("1b1712"))
		draw_circle(Vector2(9 + facing * 1.5, -34), 2.5, Color("1b1712"))
		draw_arc(Vector2(0, -27), 8, 0.2, PI - 0.2, 16, Color("54251f"), 2.8)
		if character_variant == 1:
			draw_arc(Vector2(0,-9), 22, 0.1, PI-0.1, 24, Color("d9c7ff"), 6.0)
		elif character_variant == 2:
			draw_colored_polygon(PackedVector2Array([Vector2(-18,-52),Vector2(-12,-70),Vector2(0,-57),Vector2(12,-70),Vector2(18,-52)]), Color("ffd34e"))
		elif character_variant == 3:
			draw_colored_polygon(PackedVector2Array([Vector2(7,-54),Vector2(35,-69),Vector2(28,-40)]), Color("7ed45b"))
		elif character_variant == 4:
			draw_colored_polygon(PackedVector2Array([Vector2(-4,-12),Vector2(-31,-25),Vector2(-25,1)]), Color("ffb1d2"))
			draw_colored_polygon(PackedVector2Array([Vector2(4,-12),Vector2(31,-25),Vector2(25,1)]), Color("ffb1d2"))
		elif character_variant == 5:
			draw_circle(Vector2(-18,-48), 5, Color("8fd7ff"))
			draw_circle(Vector2(19,-53), 4, Color("b7a2ff"))

	func _draw_soft_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
		var pts := PackedVector2Array()
		for i in 32:
			var a: float = TAU * i / 32.0
			pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
		draw_colored_polygon(pts, color)

	func _draw_sparkle(center: Vector2) -> void:
		var col := Color(1, 1, 1, 0.75)
		draw_line(center + Vector2(-5, 0), center + Vector2(5, 0), col, 2.0)
		draw_line(center + Vector2(0, -5), center + Vector2(0, 5), col, 2.0)

class ActiveObstacle extends AnimatableBody2D:
	# Obstacles with real behavior instead of sitting still: SWING pendulums
	# back and forth, ROTATE spins continuously, and TELEGRAPH sits idle,
	# flashes a warning, then lunges sideways and back -- so late-game routes
	# test reading and timing, not just reflexes.
	const SWING := 0
	const ROTATE := 1
	const TELEGRAPH := 2
	var behavior := SWING
	var elapsed := 0.0
	var speed := 1.1
	var swing_amplitude := 0.45
	var lunge_offset := Vector2.ZERO
	var base_position := Vector2.ZERO

	func _physics_process(delta: float) -> void:
		elapsed += delta
		match behavior:
			SWING:
				position = base_position
				rotation = sin(elapsed * speed) * swing_amplitude
			ROTATE:
				position = base_position
				rotation += speed * delta
			TELEGRAPH:
				var cycle := 3.2
				var t: float = fmod(elapsed, cycle)
				if t < 2.0:
					position = base_position
					modulate = Color(1, 1, 1, 1)
				elif t < 2.6:
					position = base_position
					modulate = Color(1, 1, 1, 1) if int(t * 12.0) % 2 == 0 else Color(1, 0.35, 0.35, 1)
				elif t < 2.85:
					position = base_position + lunge_offset * ((t - 2.6) / 0.25)
					modulate = Color(1, 0.35, 0.35, 1)
				else:
					position = base_position + lunge_offset * (1.0 - (t - 2.85) / 0.35)
					modulate = Color(1, 1, 1, 1)

class MovingPlatform extends AnimatableBody2D:
	const HORIZONTAL := 0
	const VERTICAL := 1
	const CIRCULAR := 2
	var base_position := Vector2.ZERO
	var move_amplitude := 90.0
	var move_amplitude_y := 90.0
	var move_speed := 1.2
	var move_phase := 0.0
	var elapsed := 0.0
	var motion_type := HORIZONTAL

	func _physics_process(delta: float) -> void:
		elapsed += delta
		var t: float = elapsed * move_speed + move_phase
		match motion_type:
			VERTICAL:
				position = base_position + Vector2(0, sin(t) * move_amplitude_y)
			CIRCULAR:
				position = base_position + Vector2(cos(t) * move_amplitude, sin(t) * move_amplitude_y)
			_:
				position = base_position + Vector2(sin(t) * move_amplitude, 0)

class CoinVisual extends Node2D:
	var value := 1

	func _draw() -> void:
		# Bigger, brighter coins for higher random values (1-10) so players
		# can tell at a glance which ones are worth grabbing first.
		var scale_factor: float = 1.0 + (float(value) - 1.0) / 9.0 * 0.55
		var rim: Color = Color("a86408") if value < 6 else Color("7a3fae")
		var face: Color = Color("ffd34e") if value < 6 else Color("d9a6ff")
		var core: Color = Color("e7a91d") if value < 6 else Color("a862e0")
		draw_circle(Vector2(3, 5) * scale_factor, 35 * scale_factor, Color(0, 0, 0, 0.30))
		draw_circle(Vector2.ZERO, 35 * scale_factor, rim)
		draw_circle(Vector2.ZERO, 31 * scale_factor, face)
		draw_circle(Vector2.ZERO, 24 * scale_factor, core)
		draw_arc(Vector2.ZERO, 27 * scale_factor, 0, TAU, 48, Color("fff2a3"), 3.0)
		if value >= 4:
			var font := ThemeDB.fallback_font
			var label: String = str(value)
			draw_string(font, Vector2(-8 * scale_factor, 9 * scale_factor), label, HORIZONTAL_ALIGNMENT_CENTER, -1, int(26 * scale_factor), Color("3d2004"))
		else:
			# Simple curled-worm emblem stamped into the center for low-value coins.
			draw_arc(Vector2(-2, 1) * scale_factor, 12 * scale_factor, -0.55, 4.7, 28, Color("7b4a08"), 5.0)
			draw_circle(Vector2(9, -7) * scale_factor, 3.2 * scale_factor, Color("7b4a08"))
		draw_arc(Vector2(-5, -5) * scale_factor, 21 * scale_factor, 3.5, 5.1, 18, Color(1, 1, 0.82, 0.85), 4.0)

class PowerupVisual extends Node2D:
	# 0=shield (hexagon), 1=magnet (U-shape), 2=slow-fall (feather/drop)
	var kind := 0
	var pulse := 0.0

	func _process(delta: float) -> void:
		pulse += delta
		queue_redraw()

	func _draw() -> void:
		var glow: float = 0.65 + 0.25 * sin(pulse * 3.0)
		match kind:
			0:
				var col := Color(0.45, 0.85, 1.0, 1.0)
				draw_circle(Vector2.ZERO, 34, Color(col.r, col.g, col.b, 0.28 * glow))
				var pts := PackedVector2Array()
				for i in 6:
					var a: float = TAU * i / 6.0 - PI / 2.0
					pts.append(Vector2(cos(a), sin(a)) * 24)
				draw_colored_polygon(pts, col)
				draw_polyline(pts + PackedVector2Array([pts[0]]), Color.WHITE, 3.0)
			1:
				var col := Color(0.95, 0.35, 0.35, 1.0)
				draw_circle(Vector2.ZERO, 34, Color(col.r, col.g, col.b, 0.25 * glow))
				draw_arc(Vector2(0, 4), 18, 0.3, PI - 0.3, 20, col, 9.0)
				draw_rect(Rect2(Vector2(-24, -14), Vector2(9, 20)), col, true)
				draw_rect(Rect2(Vector2(15, -14), Vector2(9, 20)), col, true)
				draw_rect(Rect2(Vector2(-24, -18), Vector2(9, 8)), Color.WHITE, true)
				draw_rect(Rect2(Vector2(15, -18), Vector2(9, 8)), Color.WHITE, true)
			_:
				var col := Color(0.6, 1.0, 0.6, 1.0)
				draw_circle(Vector2.ZERO, 34, Color(col.r, col.g, col.b, 0.25 * glow))
				draw_colored_polygon(PackedVector2Array([Vector2(0,-22),Vector2(16,0),Vector2(0,22),Vector2(-16,0)]), col)
				draw_line(Vector2(0,-18), Vector2(0,18), Color.WHITE, 2.5)

class SimpleButton extends Control:
	# A hand-drawn stand-in for Godot's built-in Button. The built-in Button
	# depends on the engine's default Theme/StyleBox resources, which appear
	# to be failing to render on some mobile export targets even though
	# Labels, ColorRects, and custom _draw() Controls render fine. This
	# draws its own background/border/text and handles touch and mouse
	# itself, so it doesn't depend on Theme at all.
	signal pressed
	var text := "":
		set(value):
			text = value
			queue_redraw()
	var font_size := 26:
		set(value):
			font_size = value
			queue_redraw()
	var text_color := Color.WHITE:
		set(value):
			text_color = value
			queue_redraw()
	var bg_color := Color(0.14, 0.30, 0.10, 0.92)
	var border_color := Color(0.72, 1.0, 0.45, 0.9)
	var disabled := false:
		set(value):
			disabled = value
			mouse_filter = MOUSE_FILTER_IGNORE if value else MOUSE_FILTER_STOP
			queue_redraw()
	var _held := false

	func _ready() -> void:
		mouse_filter = MOUSE_FILTER_STOP
		focus_mode = Control.FOCUS_NONE

	func _draw() -> void:
		var fill: Color = bg_color.darkened(0.3) if _held else bg_color
		if disabled:
			fill = Color(0.14, 0.14, 0.14, 0.75)
		draw_rect(Rect2(Vector2.ZERO, size), fill, true)
		draw_rect(Rect2(Vector2.ZERO, size), border_color if not disabled else Color(0.45, 0.45, 0.45, 0.7), false, 3.0)
		var font := ThemeDB.fallback_font
		var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var pos := Vector2((size.x - text_size.x) * 0.5, size.y * 0.5 + font_size * 0.35)
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color if not disabled else Color(0.65, 0.65, 0.65))

	func _gui_input(event: InputEvent) -> void:
		if disabled:
			return
		if event is InputEventScreenTouch:
			var touch := event as InputEventScreenTouch
			_held = touch.pressed
			queue_redraw()
			if touch.pressed:
				pressed.emit()
				accept_event()
		elif event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.button_index != MOUSE_BUTTON_LEFT:
				return
			_held = mb.pressed
			queue_redraw()
			if mb.pressed:
				pressed.emit()
				accept_event()

class MobileControls extends Control:
	# A floating joystick instead of fixed L/R buttons: wherever the player's
	# thumb first lands in the movement zone becomes the joystick center, so
	# there's no small fixed hitbox to miss on any screen size or hand position.
	# Built as a Control using _gui_input (not a Node2D using the low-level
	# _input callback) because Controls go through Godot's standard GUI/touch
	# pipeline -- the same one the character-select Buttons use -- which is
	# the reliable path for touch on exported Android/iOS/Web builds.
	const LEFT_ZONE_FRACTION := 0.58
	const JOYSTICK_RADIUS := 95.0
	const DEAD_ZONE := 16.0
	var active := false:
		set(value):
			active = value
			mouse_filter = MOUSE_FILTER_STOP if value else MOUSE_FILTER_IGNORE
			if not value:
				_release_all()
			queue_redraw()
	var boost_rect := Rect2()
	var joy_index := -1
	var joy_origin := Vector2.ZERO
	var joy_current := Vector2.ZERO
	var jump_index := -1
	var boost_index := -1

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = MOUSE_FILTER_IGNORE
		focus_mode = Control.FOCUS_NONE
		resized.connect(_layout)
		_layout()

	func _layout() -> void:
		boost_rect = Rect2(Vector2(size.x - 190, size.y - 210), Vector2(160, 160))
		queue_redraw()

	func _movement_zone() -> Rect2:
		return Rect2(Vector2.ZERO, Vector2(size.x * LEFT_ZONE_FRACTION, size.y))

	func _release_all() -> void:
		if joy_index != -1:
			Input.action_release("move_left")
			Input.action_release("move_right")
			joy_index = -1
		if jump_index != -1:
			Input.action_release("jump")
			jump_index = -1
		if boost_index != -1:
			Input.action_release("rescue")
			boost_index = -1

	func _draw() -> void:
		if not active:
			return
		var font := ThemeDB.fallback_font
		draw_rect(boost_rect, Color(0.24, 0.58, 0.10, 0.82), true)
		draw_rect(boost_rect, Color(0.82, 1.0, 0.58, 0.95), false, 4.0)
		draw_string(font, boost_rect.position + Vector2(16, 90), "BOOST", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color.WHITE)
		if joy_index != -1:
			draw_circle(joy_origin, JOYSTICK_RADIUS, Color(0.08, 0.2, 0.1, 0.5))
			draw_arc(joy_origin, JOYSTICK_RADIUS, 0, TAU, 40, Color(0.72, 1.0, 0.45, 0.85), 4.0)
			var offset: Vector2 = (joy_current - joy_origin).limit_length(JOYSTICK_RADIUS * 0.6)
			draw_circle(joy_origin + offset, 42.0, Color(0.72, 1.0, 0.45, 0.92))
		else:
			draw_string(font, Vector2(24, size.y - 40), "DRAG HERE TO MOVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.65))
		draw_string(font, Vector2(size.x * LEFT_ZONE_FRACTION + 24, size.y - 40), "TAP TO JUMP", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.65))

	func _update_move_axis() -> void:
		var dx: float = joy_current.x - joy_origin.x
		if dx < -DEAD_ZONE:
			Input.action_press("move_left")
			Input.action_release("move_right")
		elif dx > DEAD_ZONE:
			Input.action_press("move_right")
			Input.action_release("move_left")
		else:
			Input.action_release("move_left")
			Input.action_release("move_right")

	func _gui_input(event: InputEvent) -> void:
		if not active:
			return
		if event is InputEventScreenTouch:
			var touch := event as InputEventScreenTouch
			if touch.pressed:
				if boost_rect.has_point(touch.position):
					boost_index = touch.index
					Input.action_press("rescue")
				elif _movement_zone().has_point(touch.position) and joy_index == -1:
					joy_index = touch.index
					joy_origin = touch.position
					joy_current = touch.position
				elif joy_index == -1 or touch.index != joy_index:
					jump_index = touch.index
					Input.action_press("jump")
				queue_redraw()
			else:
				if touch.index == joy_index:
					Input.action_release("move_left")
					Input.action_release("move_right")
					joy_index = -1
				elif touch.index == jump_index:
					Input.action_release("jump")
					jump_index = -1
				elif touch.index == boost_index:
					Input.action_release("rescue")
					boost_index = -1
				queue_redraw()
		elif event is InputEventScreenDrag:
			var drag := event as InputEventScreenDrag
			if drag.index == joy_index:
				joy_current = drag.position
				_update_move_axis()
				queue_redraw()
		# Desktop/mouse fallback so this also works with a plain mouse, with
		# no dependency on the "emulate touch from mouse" project setting.
		elif event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.button_index != MOUSE_BUTTON_LEFT:
				return
			if mb.pressed:
				if boost_rect.has_point(mb.position):
					boost_index = 0
					Input.action_press("rescue")
				elif _movement_zone().has_point(mb.position) and joy_index == -1:
					joy_index = 0
					joy_origin = mb.position
					joy_current = mb.position
				else:
					jump_index = 0
					Input.action_press("jump")
			else:
				if joy_index == 0:
					Input.action_release("move_left")
					Input.action_release("move_right")
					joy_index = -1
				if jump_index == 0:
					Input.action_release("jump")
					jump_index = -1
				if boost_index == 0:
					Input.action_release("rescue")
					boost_index = -1
			queue_redraw()
		elif event is InputEventMouseMotion and joy_index == 0:
			joy_current = (event as InputEventMouseMotion).position
			_update_move_axis()
			queue_redraw()

class Backdrop extends Node2D:
	func _draw() -> void:
		# Long soil cutaway with soft biome bands and large roots.
		draw_rect(Rect2(-200, -154000, 7400, 155100), Color("2d251a"))
		for i in 2100:
			var x: float = fposmod(float(i * 263), 7300.0) - 80.0
			var y: float = 980.0 - fposmod(float(i * 419), 154400.0)
			var r: float = 18.0 + fposmod(float(i * 37), 55.0)
			draw_circle(Vector2(x,y), r, Color(0.32,0.24,0.14,0.34))
		for level in range(8):
			var y: float = 920.0 - level * 19200.0
			draw_rect(Rect2(0, y - 19200.0, 7000, 19200.0), Color(0.20 + level*0.012, 0.15 + level*0.015, 0.075 + level*0.008, 0.28))
			# Biome boundary is a soft root arc, not a repeated hard line.
			draw_arc(Vector2(3500, y), 3320, PI + 0.12, TAU - 0.12, 190, Color(0.34,0.23,0.10,0.38), 24.0)
			# Biome-specific distant scenery adds identity without affecting collision.
			for k in 36:
				var sx: float = 240.0 + fposmod(float(k * 877 + level * 431), 6500.0)
				var sy: float = y - 420.0 - float(k) * 505.0
				if level == 1: # Worm City tunnel lights
					draw_circle(Vector2(sx,sy), 28, Color(0.45,0.9,0.72,0.32))
					draw_arc(Vector2(sx,sy+45), 85, PI, TAU, 24, Color(0.55,0.38,0.18,0.42), 15.0)
				elif level == 2: # Fungal forest
					draw_circle(Vector2(sx,sy), 65, Color(0.82,0.34,0.28,0.26))
					draw_rect(Rect2(sx-13,sy,26,105), Color(0.75,0.64,0.44,0.24))
				elif level == 4 or level == 6: # Leaves and greenhouse growth
					draw_colored_polygon(PackedVector2Array([Vector2(sx-85,sy),Vector2(sx,sy-55),Vector2(sx+85,sy),Vector2(sx,sy+55)]), Color(0.32,0.68,0.25,0.24))
				elif level == 5: # Pond droplets
					draw_circle(Vector2(sx,sy), 38, Color(0.25,0.68,0.9,0.25))
					draw_line(Vector2(sx,sy-80),Vector2(sx,sy-35),Color(0.35,0.76,0.95,0.22),8.0)
				elif level == 7: # Sunflower canopy glow
					draw_circle(Vector2(sx,sy), 70, Color(1.0,0.67,0.12,0.22))
					draw_circle(Vector2(sx,sy), 30, Color(0.38,0.20,0.06,0.30))
		# Giant decorative roots.
		for offset in [0.0, 650.0, 1300.0, 1950.0, 2600.0, 3250.0, 3900.0, 4550.0, 5200.0, 5850.0, 6500.0]:
			var pts := PackedVector2Array()
			for j in 760:
				pts.append(Vector2(120 + offset + sin(j*.7+offset)*90, 1050 - j*205))
			draw_polyline(pts, Color("5a3f20"), 46.0, true)
			draw_polyline(pts, Color("9a7139"), 12.0, true)

func _ready() -> void:
	_setup_input()
	rng.seed = 77291
	_load_save()
	var back := Backdrop.new()
	back.z_index = -20
	add_child(back)
	_build_world()
	_build_player()
	_build_ui()
	_start_music()

func _load_save() -> void:
	unlocked_variants = []
	for i in CHARACTERS.size():
		if CHARACTERS[i].price == 0:
			unlocked_variants.append(i)
	unlocked_costumes = [0]
	selected_costume = 0
	coins = 0
	age_confirmed = false
	player_email = ""
	player_username = ""
	leaderboard = []
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		var parsed = JSON.parse_string(f.get_as_text())
		f.close()
		if typeof(parsed) == TYPE_DICTIONARY:
			coins = int(parsed.get("coins", 0))
			for v in parsed.get("unlocked", []):
				if int(v) >= 0 and int(v) < CHARACTERS.size() and not unlocked_variants.has(int(v)):
					unlocked_variants.append(int(v))
			for v in parsed.get("unlocked_costumes", []):
				if int(v) >= 0 and int(v) < COSTUMES.size() and not unlocked_costumes.has(int(v)):
					unlocked_costumes.append(int(v))
			selected_costume = int(parsed.get("selected_costume", 0))
			age_confirmed = bool(parsed.get("age_confirmed", false))
			player_email = str(parsed.get("email", ""))
			player_username = str(parsed.get("username", ""))
			var saved_board = parsed.get("leaderboard", [])
			if typeof(saved_board) == TYPE_ARRAY:
				leaderboard = saved_board

func _save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({
			"coins": coins, "unlocked": unlocked_variants,
			"unlocked_costumes": unlocked_costumes, "selected_costume": selected_costume,
			"age_confirmed": age_confirmed, "email": player_email, "username": player_username,
			"leaderboard": leaderboard,
		}))
		f.close()

func _setup_input() -> void:
	_add_keys("move_left", [KEY_A, KEY_LEFT])
	_add_keys("move_right", [KEY_D, KEY_RIGHT])
	_add_keys("jump", [KEY_SPACE, KEY_W, KEY_UP])
	_add_keys("rescue", [KEY_Q, KEY_SHIFT])
	_add_keys("restart", [KEY_R])
	_add_keys("toggle_mute", [KEY_M])

func _add_keys(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for keycode in keys:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		InputMap.action_add_event(action, event)

func _build_world() -> void:
	# A true ground floor catches every fall. Each biome then follows a long,
	# continuous side-to-side route with a guaranteed reachable checkpoint bridge.
	_add_platform(Vector2(WORLD_WIDTH * 0.5, WORLD_BOTTOM + 35), Vector2(WORLD_WIDTH, 110), true)
	_add_checkpoint(Vector2(3500, WORLD_BOTTOM - 65), 1)
	for level in range(LEVELS):
		var base_y: float = WORLD_BOTTOM - level * LEVEL_HEIGHT
		for row in range(1, 101):
			# A slow sine weave guarantees adjacent centers stay under 350 px apart.
			# The course crosses almost the full 7,000 px world without random dead ends.
			var path_step: int = level * 100 + row
			var x: float = 3500.0 + 2900.0 * sin(float(path_step) * 0.12)
			# Later stages add a second tighter weave that fades in/out at the
			# checkpoint boundaries, so transitions remain aligned and safe.
			x += float(level) * 18.0 * sin(PI * float(row) / 100.0) * sin(float(row) * 0.72)
			x = clampf(x, 260.0, WORLD_WIDTH - 260.0)
			var local_row: int = ((row - 1) % 20) + 1
			var width: float = 390.0 + float((row + level) % 5) * 38.0 - float(level) * 22.0
			var y_offset := 0.0
			# Rows 7 and 27 rise 350 px from the previous landing: a deliberate,
			# clearly marked double-jump test. The following ledge catches the route.
			var mandatory_double := row % 20 == 7 and int(row / 20) < mini(level + 1, 5)
			if mandatory_double:
				y_offset = -160.0
				width = 430.0
			# Five-piece pebble/mushroom staircases: small precision landings upward.
			var tiny_stairs := local_row >= 11 and local_row <= 15
			if tiny_stairs:
				var tiny_widths := [210.0, 175.0, 150.0, 180.0, 220.0]
				width = maxf(92.0, tiny_widths[local_row - 11] - float(level) * 13.0)
			# Three-piece narrow crossings between the staircase and next safe ledge.
			var narrow_crossing := local_row >= 17 and local_row <= 19
			if narrow_crossing:
				width = maxf(88.0, 180.0 + float((local_row + level) % 2) * 35.0 - float(level) * 13.0)
			var y: float = base_y - row * 190.0 + y_offset
			var platform_style: int = (row + level * 2) % 6
			if tiny_stairs:
				platform_style = 2 if row % 2 == 0 else 4
			var moving_interval: int = maxi(4, 14 - level * 2)
			var is_moving := row >= 35 and row < 98 and row % moving_interval == 0 and not mandatory_double and not tiny_stairs
			var motion_type: int = (row / moving_interval + level) % 3
			_add_platform(Vector2(x, y), Vector2(width, 52), false, platform_style, is_moving, level, row, motion_type)
			var obstacle_spacing: int = maxi(2, 6 - level)
			if not tiny_stairs and not narrow_crossing and not mandatory_double and (row % obstacle_spacing == 1 or row % 5 == 2):
				var obstacle_style: int = (row * 3 + level * 5) % 8
				# From Level 3 onward, roughly one in three primary obstacles gets
				# real behavior -- swinging, spinning, or telegraphing a lunge --
				# so later routes reward reading the hazard, not just dodging it.
				var obstacle_behavior := -1
				if level >= 2 and row % 3 == 0:
					obstacle_behavior = (row / 3 + level) % 3
				_add_obstacle(Vector2(x + (-70.0 if row % 2 == 0 else 70.0), y - 72.0), obstacle_style, rng.randf_range(0.8, 1.55), obstacle_behavior)
				# From Level 3 onward, some rows get a second, differently-sized obstacle
				# on the opposite side of the platform so routes read as less uniform.
				if level >= 2 and row % 4 == 3:
					var second_style: int = (row * 7 + level * 2) % 8
					_add_obstacle(Vector2(x + (70.0 if row % 2 == 0 else -70.0), y - 72.0), second_style, rng.randf_range(0.65, 1.1))
			if row % 5 == 0 or row % 5 == 2:
				_add_coin(Vector2(x, y - 72))
			if row == 45:
				_add_powerup(Vector2(x, y - 90), level % 3)
		if level < LEVELS - 1:
			var boundary_step: int = (level + 1) * 100
			var next_x: float = 3500.0 + 2900.0 * sin(float(boundary_step) * 0.12)
			var checkpoint_y: float = base_y - LEVEL_HEIGHT
			_add_platform(Vector2(next_x, checkpoint_y), Vector2(900, 64), true)
			_add_checkpoint(Vector2(next_x, checkpoint_y - 78), level + 2)
	# A broad finish garden above the sixth biome.
	_add_platform(Vector2(3500, WORLD_BOTTOM - LEVELS * LEVEL_HEIGHT), Vector2(2200, 76), true)

func _add_platform(pos: Vector2, size: Vector2, safe: bool, style: int = 0, moving: bool = false, stage: int = 0, row: int = 0, motion_type: int = 0) -> void:
	var body: Node2D
	if moving:
		var mover := MovingPlatform.new()
		mover.base_position = pos
		mover.motion_type = motion_type
		mover.move_amplitude = 35.0 + float(stage) * 22.0
		mover.move_amplitude_y = 28.0 + float(stage) * 16.0
		mover.move_speed = 1.08 + float(stage) * 0.22
		mover.move_phase = float(row) * 0.71
		body = mover
	else:
		body = StaticBody2D.new()
	body.position = pos
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collider.shape = shape
	# Platformer collision: pass upward through the underside, land from above.
	# This prevents wide checkpoint ledges from creating an impassable ceiling.
	collider.one_way_collision = true
	collider.one_way_collision_margin = 14.0
	body.add_child(collider)
	var half := size * 0.5
	var palettes := [Color("76502a"), Color("4f7c39"), Color("a9583b"), Color("75553a"), Color("65737a"), Color("8c6a2e")]
	var body_color: Color
	if moving:
		var mover_colors := [Color("2f9eaa"), Color("aa6ee0"), Color("e0a12f")]
		body_color = mover_colors[motion_type]
	elif safe:
		body_color = Color("6f8c3d")
	else:
		body_color = palettes[style]
	# One consistent, soft capsule silhouette for every material.
	var shadow := Line2D.new()
	shadow.points = PackedVector2Array([Vector2(-half.x + half.y, 7), Vector2(half.x - half.y, 7)])
	shadow.width = size.y + 12.0
	shadow.default_color = body_color.darkened(0.42)
	shadow.begin_cap_mode = Line2D.LINE_CAP_ROUND
	shadow.end_cap_mode = Line2D.LINE_CAP_ROUND
	body.add_child(shadow)
	var surface := Line2D.new()
	surface.points = PackedVector2Array([Vector2(-half.x + half.y, 0), Vector2(half.x - half.y, 0)])
	surface.width = size.y
	surface.default_color = body_color
	surface.begin_cap_mode = Line2D.LINE_CAP_ROUND
	surface.end_cap_mode = Line2D.LINE_CAP_ROUND
	body.add_child(surface)
	var moss := Line2D.new()
	moss.points = PackedVector2Array([Vector2(-half.x + half.y, -half.y + 6), Vector2(half.x - half.y, -half.y + 6)])
	moss.width = 7
	var tops := [Color("b48c45"),Color("a7cf62"),Color("e99a68"),Color("b78a5e"),Color("a8bbc0"),Color("d3ad4f")]
	if moving:
		var mover_top_colors := [Color("73e4ff"), Color("dcb3ff"), Color("ffd98a")]
		moss.default_color = mover_top_colors[motion_type]
	elif safe:
		moss.default_color = Color("b9dd61")
	else:
		moss.default_color = tops[style]
	moss.begin_cap_mode = Line2D.LINE_CAP_ROUND
	moss.end_cap_mode = Line2D.LINE_CAP_ROUND
	body.add_child(moss)
	# Small inset material marks add detail without changing the clean silhouette.
	for mark in range(3):
		var detail := Line2D.new()
		var mx: float = -half.x * 0.45 + float(mark) * half.x * 0.45
		detail.points = PackedVector2Array([Vector2(mx,-4),Vector2(mx+half.x*0.12,3)])
		detail.width = 3
		detail.default_color = body_color.lightened(0.16)
		detail.begin_cap_mode = Line2D.LINE_CAP_ROUND
		detail.end_cap_mode = Line2D.LINE_CAP_ROUND
		body.add_child(detail)
	add_child(body)

func _add_obstacle(pos: Vector2, style: int, scale_factor: float = 1.0, behavior: int = -1) -> void:
	var body: Node2D
	if behavior != -1:
		var active := ActiveObstacle.new()
		active.base_position = pos
		active.behavior = behavior
		active.speed = 0.9 + rng.randf_range(-0.15, 0.35)
		active.lunge_offset = Vector2(120.0 * (1.0 if rng.randf() > 0.5 else -1.0), 0)
		body = active
	else:
		body = StaticBody2D.new()
	body.position = pos
	var sizes := [Vector2(82,96),Vector2(110,82),Vector2(72,126),Vector2(120,76),Vector2(88,104),Vector2(46,150),Vector2(168,64),Vector2(132,110)]
	var colors := [Color("77848b"),Color("9a6938"),Color("d46b46"),Color("725137"),Color("8c9f45"),Color("9c5f5f"),Color("6d7a52"),Color("857a6a")]
	var size: Vector2 = sizes[style] * scale_factor
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	var hit_area := Area2D.new()
	var hit_shape := CollisionShape2D.new()
	var hit_rect := RectangleShape2D.new()
	hit_rect.size = size
	hit_shape.shape = hit_rect
	hit_area.add_child(hit_shape)
	hit_area.body_entered.connect(_on_obstacle_hit)
	body.add_child(hit_area)
	var h := size * 0.5
	# Rounded, cohesive obstacle silhouettes built from soft-ended strokes.
	if style == 0: # Smooth stone
		var rock := Line2D.new()
		rock.points = PackedVector2Array([Vector2(-h.x*.48,8),Vector2(h.x*.48,-4)])
		rock.width = size.y * 0.72
		rock.default_color = colors[style]
		rock.begin_cap_mode = Line2D.LINE_CAP_ROUND
		rock.end_cap_mode = Line2D.LINE_CAP_ROUND
		body.add_child(rock)
	elif style == 1: # Rounded stump
		var stump := Line2D.new()
		stump.points = PackedVector2Array([Vector2(0,h.y*.7),Vector2(0,-h.y*.55)])
		stump.width = size.x * 0.68
		stump.default_color = colors[style]
		stump.begin_cap_mode = Line2D.LINE_CAP_ROUND
		stump.end_cap_mode = Line2D.LINE_CAP_ROUND
		body.add_child(stump)
		var ring := Line2D.new()
		ring.points = PackedVector2Array([Vector2(-h.x*.24,-h.y*.56),Vector2(h.x*.24,-h.y*.56)])
		ring.width = 7
		ring.default_color = colors[style].lightened(0.28)
		ring.begin_cap_mode = Line2D.LINE_CAP_ROUND
		ring.end_cap_mode = Line2D.LINE_CAP_ROUND
		body.add_child(ring)
	elif style == 2: # Mushroom with soft stem and cap
		var stem := Line2D.new()
		stem.points = PackedVector2Array([Vector2(0,h.y*.72),Vector2(0,-h.y*.12)])
		stem.width = size.x * 0.34
		stem.default_color = Color("e5c99a")
		stem.begin_cap_mode = Line2D.LINE_CAP_ROUND
		stem.end_cap_mode = Line2D.LINE_CAP_ROUND
		body.add_child(stem)
		var cap := Line2D.new()
		cap.points = PackedVector2Array([Vector2(-h.x*.62,-h.y*.30),Vector2(0,-h.y*.62),Vector2(h.x*.62,-h.y*.30)])
		cap.width = size.y * 0.34
		cap.default_color = colors[style]
		cap.joint_mode = Line2D.LINE_JOINT_ROUND
		cap.begin_cap_mode = Line2D.LINE_CAP_ROUND
		cap.end_cap_mode = Line2D.LINE_CAP_ROUND
		body.add_child(cap)
	elif style == 3: # Root/log
		var log_shape := Line2D.new()
		log_shape.points = PackedVector2Array([Vector2(-h.x*.65,6),Vector2(-h.x*.15,-8),Vector2(h.x*.65,3)])
		log_shape.width = size.y * 0.58
		log_shape.default_color = colors[style]
		log_shape.joint_mode = Line2D.LINE_JOINT_ROUND
		log_shape.begin_cap_mode = Line2D.LINE_CAP_ROUND
		log_shape.end_cap_mode = Line2D.LINE_CAP_ROUND
		body.add_child(log_shape)
	elif style == 4: # Sprout
		var sprout := Line2D.new()
		sprout.points = PackedVector2Array([Vector2(0,h.y*.72),Vector2(0,-h.y*.55)])
		sprout.width = 13
		sprout.default_color = colors[style]
		sprout.begin_cap_mode = Line2D.LINE_CAP_ROUND
		sprout.end_cap_mode = Line2D.LINE_CAP_ROUND
		body.add_child(sprout)
		for side in [-1.0,1.0]:
			var leaf := Line2D.new()
			leaf.points = PackedVector2Array([Vector2(0,-12),Vector2(side*h.x*.55,-h.y*.48)])
			leaf.width = 18
			leaf.default_color = colors[style].lightened(0.12)
			leaf.begin_cap_mode = Line2D.LINE_CAP_ROUND
			leaf.end_cap_mode = Line2D.LINE_CAP_ROUND
			body.add_child(leaf)
	elif style == 5: # Thin root spike - tall and narrow, tests precise footing
		var spike := Line2D.new()
		spike.points = PackedVector2Array([Vector2(0,h.y*.75),Vector2(0,-h.y*.7)])
		spike.width = size.x * 0.5
		spike.default_color = colors[style]
		spike.begin_cap_mode = Line2D.LINE_CAP_ROUND
		spike.end_cap_mode = Line2D.LINE_CAP_ROUND
		body.add_child(spike)
		var spike_tip := Line2D.new()
		spike_tip.points = PackedVector2Array([Vector2(0,-h.y*.55),Vector2(0,-h.y*.92)])
		spike_tip.width = size.x * 0.22
		spike_tip.default_color = colors[style].lightened(0.2)
		spike_tip.begin_cap_mode = Line2D.LINE_CAP_ROUND
		spike_tip.end_cap_mode = Line2D.LINE_CAP_ROUND
		body.add_child(spike_tip)
	elif style == 6: # Wide low barrier - forces a jump rather than a dodge
		var bar := Line2D.new()
		bar.points = PackedVector2Array([Vector2(-h.x*.62,4),Vector2(h.x*.62,-2)])
		bar.width = size.y * 0.7
		bar.default_color = colors[style]
		bar.begin_cap_mode = Line2D.LINE_CAP_ROUND
		bar.end_cap_mode = Line2D.LINE_CAP_ROUND
		body.add_child(bar)
		var bar_top := Line2D.new()
		bar_top.points = PackedVector2Array([Vector2(-h.x*.55,-h.y*.32),Vector2(h.x*.55,-h.y*.36)])
		bar_top.width = 8
		bar_top.default_color = colors[style].lightened(0.25)
		bar_top.begin_cap_mode = Line2D.LINE_CAP_ROUND
		bar_top.end_cap_mode = Line2D.LINE_CAP_ROUND
		body.add_child(bar_top)
	else: # Boulder cluster - three uneven stones grouped together
		var offsets := [Vector2(-h.x*.5,h.y*.28),Vector2(h.x*.32,h.y*.42),Vector2(h.x*.02,-h.y*.35)]
		var radii := [h.x*.42,h.x*.34,h.x*.5]
		for i in 3:
			var stone := Line2D.new()
			stone.points = PackedVector2Array([offsets[i] - Vector2(radii[i]*.6,0), offsets[i] + Vector2(radii[i]*.6,0)])
			stone.width = radii[i] * 1.5
			stone.default_color = colors[style].darkened(float(i) * 0.08)
			stone.begin_cap_mode = Line2D.LINE_CAP_ROUND
			stone.end_cap_mode = Line2D.LINE_CAP_ROUND
			body.add_child(stone)
	add_child(body)

func _add_checkpoint(pos: Vector2, level: int) -> void:
	var area := Area2D.new()
	area.position = pos
	area.set_meta("level", level)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 72
	shape.shape = circle
	area.add_child(shape)
	var glow := PointLight2D.new()
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(1,0.78,0.22,0.75),Color(1,0.5,0,0)])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 128
	tex.height = 128
	tex.fill = GradientTexture2D.FILL_RADIAL
	glow.texture = tex
	glow.energy = 1.4
	glow.texture_scale = 2.4
	area.add_child(glow)
	var icon := Label.new()
	icon.text = "❧"
	icon.position = Vector2(-30,-50)
	icon.add_theme_font_size_override("font_size", 76)
	icon.add_theme_color_override("font_color", Color("caff69"))
	area.add_child(icon)
	area.body_entered.connect(_on_checkpoint.bind(area))
	checkpoint_markers.append(area)
	add_child(area)

func _add_coin(pos: Vector2) -> void:
	var coin := Area2D.new()
	coin.position = pos
	coin.add_to_group("coins")
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 32
	shape.shape = circle
	coin.add_child(shape)
	var value: int = rng.randi_range(1, 10)
	coin.set_meta("value", value)
	var visual := CoinVisual.new()
	visual.value = value
	coin.add_child(visual)
	coin.body_entered.connect(_collect_coin.bind(coin))
	add_child(coin)

func _collect_coin(body: Node2D, coin: Area2D) -> void:
	if body != player or not is_instance_valid(coin):
		return
	var value: int = int(coin.get_meta("value", 1))
	# Combo/streak: coins collected within COMBO_WINDOW seconds of each other
	# chain together; every 5th streak step pays an escalating bonus.
	if combo_timer > 0.0:
		combo_streak += 1
	else:
		combo_streak = 1
	combo_timer = COMBO_WINDOW
	var bonus := 0
	if combo_streak % 5 == 0:
		bonus = combo_streak
	coins += value + bonus
	coin_label.text = "COINS: %d" % coins
	combo_label.text = "COMBO x%d" % combo_streak if combo_streak > 1 else ""
	if bonus > 0:
		status_label.text = "+%d COINS · COMBO x%d! +%d BONUS" % [value, combo_streak, bonus]
	else:
		status_label.text = "+%d COINS · %d TOTAL" % [value, coins]
	status_timer = 1.4
	coin.queue_free()
	_save_game()

func _add_powerup(pos: Vector2, kind: int) -> void:
	var area := Area2D.new()
	area.position = pos
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 34
	shape.shape = circle
	area.add_child(shape)
	var visual := PowerupVisual.new()
	visual.kind = kind
	area.add_child(visual)
	area.body_entered.connect(_collect_powerup.bind(area, kind))
	add_child(area)

func _collect_powerup(body: Node2D, area: Area2D, kind: int) -> void:
	if body != player or not is_instance_valid(area):
		return
	match kind:
		0:
			shield_charges = mini(shield_charges + 1, 3)
			status_label.text = "🛡️ SHIELD +1 (%d TOTAL)" % shield_charges
		1:
			magnet_timer = MAGNET_DURATION
			status_label.text = "🧲 MAGNET ACTIVE!"
		_:
			slowfall_timer = SLOWFALL_DURATION
			status_label.text = "🪶 SLOW-FALL ACTIVE!"
	status_timer = 2.0
	area.queue_free()

func _build_player() -> void:
	player = Worm.new()
	player.position = checkpoint
	player.z_index = 10
	add_child(player)
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.5
	camera.limit_left = 0
	camera.limit_right = int(WORLD_WIDTH)
	camera.limit_bottom = 1080
	camera.limit_top = int(WORLD_BOTTOM - LEVELS * LEVEL_HEIGHT - 600)
	player.add_child(camera)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var shade := ColorRect.new()
	shade.position = Vector2(22,22)
	shade.size = Vector2(760,130)
	shade.color = Color(0.035,0.055,0.025,0.86)
	layer.add_child(shade)
	level_label = _label(Vector2(52,42), 34, Color("f5f1cf"), "LEVEL 1 · EASY · COMPOST FLOOR")
	layer.add_child(level_label)
	height_label = _label(Vector2(54,94), 25, Color("a8dc70"), "HEIGHT 0 m")
	layer.add_child(height_label)
	coin_label = _label(Vector2(1540,40), 30, Color("ffd34e"), "COINS: 0")
	coin_label.size = Vector2(330,60)
	coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	layer.add_child(coin_label)
	combo_label = _label(Vector2(1540,100), 24, Color("ffb45c"), "")
	combo_label.size = Vector2(330,40)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	layer.add_child(combo_label)
	powerup_label = _label(Vector2(54,130), 22, Color("bfe6ff"), "")
	powerup_label.size = Vector2(500,40)
	layer.add_child(powerup_label)
	hint_label = _label(Vector2(50,995), 22, Color(1,1,1,0.82), "Move/jump/boost as before · R: checkpoint · M: mute · Chain coins fast for combo bonuses · Obstacles break your combo unless you have a shield")
	layer.add_child(hint_label)
	status_label = _label(Vector2(690,52), 30, Color("ffe578"), status_text)
	status_label.size = Vector2(600,55)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(status_label)
	rescue_button = Control.new()
	rescue_button.position = Vector2(1630,810)
	rescue_button.custom_minimum_size = Vector2(230,230)
	layer.add_child(rescue_button)
	var circle := GradientTexture2D.new()
	var rect := TextureRect.new()
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(0.52,1,0.34,0.92),Color(0.06,0.18,0.08,0.94)])
	circle.gradient = g
	circle.width = 192
	circle.height = 192
	circle.fill = GradientTexture2D.FILL_RADIAL
	rect.texture = circle
	rect.size = Vector2(190,190)
	rect.position = Vector2(20,0)
	rescue_button.add_child(rect)
	ability_label = _label(Vector2(0,184), 26, Color("eaffb5"), "UNLOCKS AT LEVEL 2")
	ability_label.size = Vector2(230,70)
	ability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rescue_button.add_child(ability_label)
	var wings := _label(Vector2(60,40), 72, Color.WHITE, "❧")
	wings.size = Vector2(110,100)
	wings.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rescue_button.add_child(wings)
	mute_button = SimpleButton.new()
	mute_button.position = Vector2(1540, 148)
	mute_button.size = Vector2(220, 56)
	mute_button.text = "🔊 MUSIC"
	mute_button.font_size = 22
	mute_button.pressed.connect(_toggle_mute)
	layer.add_child(mute_button)
	_build_touch_controls(layer)
	_build_character_menu(layer)
	_build_store_overlay(layer)
	_build_stage_overlay(layer)
	_build_win_overlay(layer)
	_build_leaderboard_overlay(layer)
	_build_login_screen(layer)
	character_menu.hide()
	if age_confirmed and player_username != "":
		character_menu.show()
	else:
		login_screen.show()

func _build_login_screen(layer: CanvasLayer) -> void:
	login_screen = ColorRect.new()
	login_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	login_screen.color = Color(0.03,0.05,0.03,0.98)
	login_screen.hide()
	layer.add_child(login_screen)
	var title := _label(Vector2(560,120), 54, Color("eaffb5"), "WELCOME TO TERRACAST")
	title.size = Vector2(800,80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	login_screen.add_child(title)
	var subtitle := _label(Vector2(460,205), 22, Color("cfe8b0"), "Create a profile to save your coins, climbers, and leaderboard spot.\nThis is stored on this device only -- not a real account system yet.")
	subtitle.size = Vector2(1000,70)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	login_screen.add_child(subtitle)
	age_toggle = SimpleButton.new()
	age_toggle.position = Vector2(660,300)
	age_toggle.size = Vector2(600,60)
	age_toggle.text = "☐  I am 13 years of age or older"
	age_toggle.font_size = 22
	age_toggle.pressed.connect(_toggle_age_confirm)
	login_screen.add_child(age_toggle)
	var email_label := _label(Vector2(660,380), 20, Color("f2e4b6"), "EMAIL")
	login_screen.add_child(email_label)
	email_field = LineEdit.new()
	email_field.position = Vector2(660,408)
	email_field.size = Vector2(600,58)
	email_field.placeholder_text = "you@example.com"
	login_screen.add_child(email_field)
	var username_label := _label(Vector2(660,480), 20, Color("f2e4b6"), "USERNAME (no real names, please)")
	login_screen.add_child(username_label)
	username_field = LineEdit.new()
	username_field.position = Vector2(660,508)
	username_field.size = Vector2(600,58)
	username_field.placeholder_text = "e.g. MossyClimber"
	username_field.max_length = 16
	login_screen.add_child(username_field)
	login_error_label = _label(Vector2(660,578), 20, Color("ff9a8a"), "")
	login_error_label.size = Vector2(600,40)
	login_screen.add_child(login_error_label)
	var continue_button := SimpleButton.new()
	continue_button.position = Vector2(760,635)
	continue_button.size = Vector2(400,80)
	continue_button.text = "CONTINUE"
	continue_button.font_size = 28
	continue_button.pressed.connect(_submit_login)
	login_screen.add_child(continue_button)

func _toggle_age_confirm() -> void:
	age_confirmed = not age_confirmed
	age_toggle.text = "☑  I am 13 years of age or older" if age_confirmed else "☐  I am 13 years of age or older"

func _contains_blocked_word(name: String) -> bool:
	var lower := name.to_lower()
	for word in BLOCKED_WORDS:
		if lower.contains(word):
			return true
	return false

func _submit_login() -> void:
	if not age_confirmed:
		login_error_label.text = "Please confirm you're 13 or older to continue."
		return
	var email: String = email_field.text.strip_edges()
	if not (email.contains("@") and email.contains(".") and email.length() > 5):
		login_error_label.text = "Enter a valid email address."
		return
	var name: String = username_field.text.strip_edges()
	if name.length() < 3:
		login_error_label.text = "Username must be at least 3 characters."
		return
	if _contains_blocked_word(name):
		login_error_label.text = "That username isn't allowed -- try another."
		return
	player_email = email
	player_username = name
	_save_game()
	login_screen.hide()
	character_menu.show()

func _build_leaderboard_overlay(layer: CanvasLayer) -> void:
	leaderboard_overlay = ColorRect.new()
	leaderboard_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	leaderboard_overlay.color = Color(0.03,0.05,0.06,0.97)
	leaderboard_overlay.hide()
	layer.add_child(leaderboard_overlay)
	var title := _label(Vector2(660,80), 54, Color("ffe578"), "🏆 LEADERBOARD")
	title.size = Vector2(600,80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	leaderboard_overlay.add_child(title)
	var subtitle := _label(Vector2(560,165), 22, Color("cfe8b0"), "Fastest full 16,000 m climbs on this device")
	subtitle.size = Vector2(800,40)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	leaderboard_overlay.add_child(subtitle)
	var back_button := SimpleButton.new()
	back_button.position = Vector2(1650, 60)
	back_button.size = Vector2(210, 65)
	back_button.text = "← BACK"
	back_button.font_size = 24
	back_button.pressed.connect(leaderboard_overlay.hide)
	leaderboard_overlay.add_child(back_button)
	leaderboard_list_box = Control.new()
	leaderboard_list_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	leaderboard_overlay.add_child(leaderboard_list_box)

func _populate_leaderboard() -> void:
	for child in leaderboard_list_box.get_children():
		child.queue_free()
	if leaderboard.is_empty():
		var empty_label := _label(Vector2(560,260), 26, Color(1,1,1,0.7), "No completed climbs yet -- be the first!")
		empty_label.size = Vector2(800,50)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		leaderboard_list_box.add_child(empty_label)
		return
	for i in leaderboard.size():
		var entry: Dictionary = leaderboard[i]
		var row_y: float = 250 + i * 62
		var rank_label := _label(Vector2(500, row_y), 26, Color("ffd34e"), "#%d" % (i + 1))
		rank_label.size = Vector2(70,45)
		leaderboard_list_box.add_child(rank_label)
		var name_label := _label(Vector2(590, row_y), 26, Color("eaffb5"), str(entry.get("name", "???")))
		name_label.size = Vector2(500,45)
		leaderboard_list_box.add_child(name_label)
		var minutes: int = int(entry.get("time", 0)) / 60
		var seconds: int = int(entry.get("time", 0)) % 60
		var time_label := _label(Vector2(1120, row_y), 26, Color("a8dc70"), "%d:%02d" % [minutes, seconds])
		time_label.size = Vector2(160,45)
		leaderboard_list_box.add_child(time_label)
		var coins_label := _label(Vector2(1310, row_y), 26, Color("ffd34e"), "%d coins" % int(entry.get("coins", 0)))
		coins_label.size = Vector2(220,45)
		leaderboard_list_box.add_child(coins_label)

func _record_leaderboard_entry(time_seconds: float) -> void:
	leaderboard.append({"name": player_username, "time": int(time_seconds), "coins": coins})
	leaderboard.sort_custom(func(a, b): return int(a.get("time", 0)) < int(b.get("time", 0)))
	leaderboard = leaderboard.slice(0, 10)
	_save_game()

func _open_leaderboard() -> void:
	_populate_leaderboard()
	leaderboard_overlay.show()

func _build_touch_controls(layer: CanvasLayer) -> void:
	mobile_controls = MobileControls.new()
	layer.add_child(mobile_controls)

func _build_character_menu(layer: CanvasLayer) -> void:
	player.set_physics_process(false)
	character_menu = ColorRect.new()
	character_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	character_menu.color = Color(0.035,0.045,0.025,0.97)
	layer.add_child(character_menu)
	var title := _label(Vector2(480,90), 64, Color("eaffb5"), "CHOOSE YOUR CLIMBER")
	title.size = Vector2(960,90)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	character_menu.add_child(title)
	var subtitle := _label(Vector2(510,175), 28, Color("f2e4b6"), "Eight separate stages · 100 route platforms each · 16,000 meters total")
	subtitle.size = Vector2(900,50)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	character_menu.add_child(subtitle)
	var store_button := SimpleButton.new()
	store_button.position = Vector2(560, 235)
	store_button.size = Vector2(380, 70)
	store_button.text = "🛒 STORE"
	store_button.font_size = 26
	store_button.pressed.connect(_open_store)
	character_menu.add_child(store_button)
	var leaderboard_button := SimpleButton.new()
	leaderboard_button.position = Vector2(980, 235)
	leaderboard_button.size = Vector2(380, 70)
	leaderboard_button.text = "🏆 LEADERBOARD"
	leaderboard_button.font_size = 26
	leaderboard_button.pressed.connect(_open_leaderboard)
	character_menu.add_child(leaderboard_button)
	character_list_box = Control.new()
	character_list_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	character_menu.add_child(character_list_box)
	_populate_character_menu()

func _populate_character_menu() -> void:
	for child in character_list_box.get_children():
		child.queue_free()
	var total: int = unlocked_variants.size()
	var max_page: int = maxi(0, (total - 1) / CHAR_PAGE_SIZE)
	char_page = clampi(char_page, 0, max_page)
	var start: int = char_page * CHAR_PAGE_SIZE
	var end: int = mini(start + CHAR_PAGE_SIZE, total)
	for idx in range(start, end):
		var slot: int = idx - start
		var variant: int = unlocked_variants[idx]
		var data: Dictionary = CHARACTERS[variant]
		var col: int = slot % 2
		var row: int = slot / 2
		var card := ColorRect.new()
		card.position = Vector2(500 + col * 470, 320 + row * 150)
		card.size = Vector2(420, 130)
		card.color = Color(0.08, 0.10, 0.07, 0.85)
		character_list_box.add_child(card)
		var thumb := TextureRect.new()
		thumb.texture = load("res://assets/characters/%s" % str(data.sprite))
		thumb.position = Vector2(10, 6)
		thumb.size = Vector2(90, 118)
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(thumb)
		var button := SimpleButton.new()
		button.position = Vector2(108, 40)
		button.size = Vector2(300, 52)
		button.text = "PLAY AS %s" % str(data.name)
		button.font_size = 22
		button.text_color = (data.color as Color).lightened(0.45)
		button.pressed.connect(_select_character.bind(data.name, data.color, variant))
		card.add_child(button)
	if max_page > 0:
		var page_label := _label(Vector2(870, 800), 22, Color(1,1,1,0.8), "PAGE %d / %d" % [char_page + 1, max_page + 1])
		page_label.size = Vector2(200, 40)
		character_list_box.add_child(page_label)
		if char_page > 0:
			var prev_btn := SimpleButton.new()
			prev_btn.position = Vector2(680, 795)
			prev_btn.size = Vector2(150, 50)
			prev_btn.text = "◀ PREV"
			prev_btn.font_size = 20
			prev_btn.pressed.connect(func(): char_page -= 1; _populate_character_menu())
			character_list_box.add_child(prev_btn)
		if char_page < max_page:
			var next_btn := SimpleButton.new()
			next_btn.position = Vector2(1090, 795)
			next_btn.size = Vector2(150, 50)
			next_btn.text = "NEXT ▶"
			next_btn.font_size = 20
			next_btn.pressed.connect(func(): char_page += 1; _populate_character_menu())
			character_list_box.add_child(next_btn)

func _select_character(character_name: String, color: Color, variant: int) -> void:
	player.set("body_color", color)
	player.set("character_variant", variant)
	player.set("costume", int(COSTUMES[selected_costume].pattern))
	var sprite_path: String = str(CHARACTERS[variant].sprite)
	player.set("sprite_texture", load("res://assets/characters/%s" % sprite_path))
	player.queue_redraw()
	character_menu.hide()
	game_started = true
	mobile_controls.active = true
	player.set_physics_process(true)
	run_start_time = Time.get_ticks_msec() / 1000.0
	status_label.text = "%s, %s BEGINS THE 16,000 m CLIMB!" % [player_username, character_name]
	status_timer = 4.0

func _build_store_overlay(layer: CanvasLayer) -> void:
	store_overlay = ColorRect.new()
	store_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	store_overlay.color = Color(0.03,0.04,0.06,0.97)
	store_overlay.hide()
	layer.add_child(store_overlay)
	var title := _label(Vector2(600,70), 54, Color("ffe578"), "CLIMBER STORE")
	title.size = Vector2(720,80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	store_overlay.add_child(title)
	store_coin_label = _label(Vector2(710,150), 30, Color("ffd34e"), "COINS: 0")
	store_coin_label.size = Vector2(500,45)
	store_coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	store_overlay.add_child(store_coin_label)
	var back_button := SimpleButton.new()
	back_button.position = Vector2(1650, 55)
	back_button.size = Vector2(210, 60)
	back_button.text = "← BACK"
	back_button.font_size = 24
	back_button.pressed.connect(_close_store)
	store_overlay.add_child(back_button)
	var tab_chars := SimpleButton.new()
	tab_chars.position = Vector2(560, 205)
	tab_chars.size = Vector2(380, 55)
	tab_chars.text = "CLIMBERS"
	tab_chars.font_size = 22
	tab_chars.pressed.connect(func(): store_tab = "characters"; _populate_store())
	store_overlay.add_child(tab_chars)
	var tab_costumes := SimpleButton.new()
	tab_costumes.position = Vector2(980, 205)
	tab_costumes.size = Vector2(380, 55)
	tab_costumes.text = "COSTUMES"
	tab_costumes.font_size = 22
	tab_costumes.pressed.connect(func(): store_tab = "costumes"; _populate_store())
	store_overlay.add_child(tab_costumes)
	store_list_box = Control.new()
	store_list_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	store_overlay.add_child(store_list_box)

func _populate_store() -> void:
	for child in store_list_box.get_children():
		child.queue_free()
	store_coin_label.text = "COINS: %d" % coins
	if store_tab == "costumes":
		_populate_store_costumes()
	else:
		_populate_store_characters()

func _populate_store_characters() -> void:
	var total: int = CHARACTERS.size()
	var max_page: int = maxi(0, (total - 1) / STORE_PAGE_SIZE)
	store_char_page = clampi(store_char_page, 0, max_page)
	var start: int = store_char_page * STORE_PAGE_SIZE
	var end: int = mini(start + STORE_PAGE_SIZE, total)
	for idx in range(start, end):
		var slot: int = idx - start
		var i: int = idx
		var data: Dictionary = CHARACTERS[i]
		var owned: bool = unlocked_variants.has(i)
		var row: int = slot / 3
		var col: int = slot % 3
		# A plain ColorRect, not a themed Panel, for the same reason buttons
		# were switched to SimpleButton -- no dependency on engine Theme resources.
		var card := ColorRect.new()
		card.position = Vector2(360 + col * 420, 300 + row * 210)
		card.size = Vector2(390, 195)
		card.color = Color(0.08, 0.10, 0.14, 0.88)
		store_list_box.add_child(card)
		var tier: String = str(data.get("tier", "COMMON"))
		var tier_color: Color = TIER_COLORS.get(tier, Color.GRAY)
		var tier_badge := ColorRect.new()
		tier_badge.position = Vector2(20, 14)
		tier_badge.size = Vector2(14, 14)
		tier_badge.color = tier_color
		card.add_child(tier_badge)
		var name_label := _label(Vector2(42, 6), 20, (data.color as Color).lightened(0.45), str(data.name))
		name_label.size = Vector2(240, 28)
		card.add_child(name_label)
		var tier_label := _label(Vector2(42, 32), 15, tier_color, tier)
		tier_label.size = Vector2(200, 22)
		card.add_child(tier_label)
		var thumb := TextureRect.new()
		thumb.texture = load("res://assets/characters/%s" % str(data.sprite))
		thumb.position = Vector2(280, 8)
		thumb.size = Vector2(96, 120)
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		card.add_child(thumb)
		var action := SimpleButton.new()
		action.position = Vector2(20, 138)
		action.size = Vector2(350, 44)
		action.font_size = 19
		if owned:
			action.text = "✓ OWNED"
			action.disabled = true
		elif coins >= int(data.price):
			action.text = "BUY · %d COINS" % int(data.price)
			action.pressed.connect(_buy_character.bind(i))
		else:
			action.text = "NEED %d COINS" % int(data.price)
			action.disabled = true
		card.add_child(action)
	if max_page > 0:
		var page_label := _label(Vector2(870, 950), 22, Color(1,1,1,0.8), "PAGE %d / %d" % [store_char_page + 1, max_page + 1])
		page_label.size = Vector2(200, 40)
		store_list_box.add_child(page_label)
		if store_char_page > 0:
			var prev_btn := SimpleButton.new()
			prev_btn.position = Vector2(680, 945)
			prev_btn.size = Vector2(150, 50)
			prev_btn.text = "◀ PREV"
			prev_btn.font_size = 20
			prev_btn.pressed.connect(func(): store_char_page -= 1; _populate_store())
			store_list_box.add_child(prev_btn)
		if store_char_page < max_page:
			var next_btn := SimpleButton.new()
			next_btn.position = Vector2(1090, 945)
			next_btn.size = Vector2(150, 50)
			next_btn.text = "NEXT ▶"
			next_btn.font_size = 20
			next_btn.pressed.connect(func(): store_char_page += 1; _populate_store())
			store_list_box.add_child(next_btn)

func _populate_store_costumes() -> void:
	var row := 0
	for i in COSTUMES.size():
		var data: Dictionary = COSTUMES[i]
		var owned: bool = unlocked_costumes.has(i)
		var equipped: bool = selected_costume == i
		var card := ColorRect.new()
		card.position = Vector2(360 + (row % 3) * 420, 300 + int(row / 3) * 210)
		card.size = Vector2(390, 190)
		card.color = Color(0.11, 0.16, 0.10, 0.92) if equipped else Color(0.09, 0.10, 0.14, 0.88)
		store_list_box.add_child(card)
		var tier: String = str(data.get("tier", "COMMON"))
		var tier_color: Color = TIER_COLORS.get(tier, Color.GRAY)
		var tier_badge := ColorRect.new()
		tier_badge.position = Vector2(20, 18)
		tier_badge.size = Vector2(14, 14)
		tier_badge.color = tier_color
		card.add_child(tier_badge)
		var name_label := _label(Vector2(42, 10), 22, Color.WHITE, data.name)
		name_label.size = Vector2(330, 30)
		card.add_child(name_label)
		var tier_label := _label(Vector2(42, 36), 16, tier_color, tier)
		tier_label.size = Vector2(200, 24)
		card.add_child(tier_label)
		var action := SimpleButton.new()
		action.position = Vector2(20, 130)
		action.size = Vector2(350, 46)
		action.font_size = 20
		if equipped:
			action.text = "✓ EQUIPPED"
			action.disabled = true
		elif owned:
			action.text = "EQUIP"
			action.pressed.connect(_equip_costume.bind(i))
		elif coins >= int(data.price):
			action.text = "BUY · %d COINS" % int(data.price)
			action.pressed.connect(_buy_costume.bind(i))
		else:
			action.text = "NEED %d COINS" % int(data.price)
			action.disabled = true
		card.add_child(action)
		row += 1

func _buy_character(variant: int) -> void:
	var data: Dictionary = CHARACTERS[variant]
	if unlocked_variants.has(variant) or coins < int(data.price):
		return
	coins -= int(data.price)
	unlocked_variants.append(variant)
	_save_game()
	_populate_store()
	coin_label.text = "COINS: %d" % coins

func _buy_costume(i: int) -> void:
	var data: Dictionary = COSTUMES[i]
	if unlocked_costumes.has(i) or coins < int(data.price):
		return
	coins -= int(data.price)
	unlocked_costumes.append(i)
	_save_game()
	_populate_store()
	coin_label.text = "COINS: %d" % coins

func _equip_costume(i: int) -> void:
	if not unlocked_costumes.has(i):
		return
	selected_costume = i
	_save_game()
	_populate_store()
	if player:
		player.set("costume", int(COSTUMES[i].pattern))
		player.queue_redraw()

func _open_store() -> void:
	character_menu.hide()
	_populate_store()
	store_overlay.show()

func _close_store() -> void:
	store_overlay.hide()
	_populate_character_menu()
	character_menu.show()

func _build_stage_overlay(layer: CanvasLayer) -> void:
	stage_overlay = ColorRect.new()
	stage_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage_overlay.color = Color(0.025,0.065,0.035,0.97)
	stage_overlay.hide()
	layer.add_child(stage_overlay)
	stage_overlay_title = _label(Vector2(360,210), 78, Color("fff27a"), "STAGE COMPLETE!")
	stage_overlay_title.size = Vector2(1200,105)
	stage_overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_overlay.add_child(stage_overlay_title)
	stage_overlay_detail = _label(Vector2(350,345), 36, Color("dfffb4"), "2,000 METERS CLEARED")
	stage_overlay_detail.size = Vector2(1220,150)
	stage_overlay_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_overlay.add_child(stage_overlay_detail)
	var continue_button := SimpleButton.new()
	continue_button.position = Vector2(710,575)
	continue_button.size = Vector2(500,110)
	continue_button.text = "ENTER NEXT STAGE"
	continue_button.font_size = 33
	continue_button.pressed.connect(_begin_next_stage)
	stage_overlay.add_child(continue_button)

func _show_stage_transition(next_level: int) -> void:
	var difficulties := ["EASY", "NORMAL", "HARD", "SUPER HARD", "EXTRA HARD", "CRAZY HARD", "IMPOSSIBLE", "NO WAY BRUH"]
	var names := ["COMPOST FLOOR", "WORM CITY", "FUNGAL FOREST", "ROOT ZONE", "GARDEN BED", "POND EDGE", "GREENHOUSE", "SUNFLOWER CANOPY"]
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	stage_overlay_title.text = "STAGE %d COMPLETE!" % (next_level - 1)
	stage_overlay_detail.text = "2,000 METERS CLEARED\nNEXT: STAGE %d · %s · %s\nNEW RESCUE BOOST EARNED" % [next_level, difficulties[next_level - 1], names[next_level - 1]]
	stage_overlay.show()

func _begin_next_stage() -> void:
	stage_overlay.hide()
	player.position = checkpoint
	player.velocity = Vector2.ZERO
	player.set_physics_process(true)
	status_label.text = "STAGE %d BEGINS · 0 / 2,000 m" % checkpoint_level
	status_timer = 4.0

func _build_win_overlay(layer: CanvasLayer) -> void:
	win_overlay = ColorRect.new()
	win_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	win_overlay.color = Color(0.02,0.08,0.035,0.95)
	win_overlay.hide()
	layer.add_child(win_overlay)
	var title := _label(Vector2(410,230), 104, Color("fff17a"), "YOU WON!")
	title.size = Vector2(1100,135)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_overlay.add_child(title)
	var message := _label(Vector2(410,385), 40, Color("d9ffb2"), "16,000 METERS · NO WAY BRUH CONQUERED")
	message.size = Vector2(1100,80)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_overlay.add_child(message)
	var again := SimpleButton.new()
	again.position = Vector2(730,560)
	again.size = Vector2(460,105)
	again.text = "CLIMB AGAIN"
	again.font_size = 34
	again.pressed.connect(func(): get_tree().reload_current_scene())
	win_overlay.add_child(again)

func _label(pos: Vector2, size: int, color: Color, text: String) -> Label:
	var l := Label.new()
	l.position = pos
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0,0,0,0.8))
	l.add_theme_constant_override("shadow_offset_x", 3)
	l.add_theme_constant_override("shadow_offset_y", 3)
	return l

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_mute"):
		_toggle_mute()

func _physics_process(delta: float) -> void:
	if not game_started or won:
		return
	if Input.is_action_just_pressed("restart"):
		_respawn()
	# Combo streak decays once the window since the last coin closes.
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0 and combo_streak > 0:
			combo_streak = 0
			combo_label.text = ""
	obstacle_hit_cooldown = maxf(0.0, obstacle_hit_cooldown - delta)
	# Magnet: pull nearby coins toward the player; they self-collect on contact.
	if magnet_timer > 0.0:
		magnet_timer -= delta
		for c in get_tree().get_nodes_in_group("coins"):
			if is_instance_valid(c) and c.global_position.distance_to(player.global_position) < MAGNET_RADIUS:
				c.global_position = c.global_position.move_toward(player.global_position, 950.0 * delta)
	# Slow-fall: temporarily reduce gravity, restored once the timer ends.
	if slowfall_timer > 0.0:
		slowfall_timer -= delta
		player.gravity = 480.0
	else:
		player.gravity = DEFAULT_GRAVITY
	var effects: Array[String] = []
	if shield_charges > 0:
		effects.append("🛡️ x%d" % shield_charges)
	if magnet_timer > 0.0:
		effects.append("🧲 %.0fs" % magnet_timer)
	if slowfall_timer > 0.0:
		effects.append("🪶 %.0fs" % slowfall_timer)
	powerup_label.text = "   ".join(effects)
	var height: float = maxf(0.0, WORLD_BOTTOM - player.position.y)
	best_height = max(best_height, height)
	var current_level := clampi(int(height / LEVEL_HEIGHT) + 1, 1, LEVELS)
	var local_height: float = height - float(current_level - 1) * LEVEL_HEIGHT
	var stage_meters: int = clampi(int(local_height / 9.6), 0, 2000)
	var total_meters: int = clampi(int(height / 9.6), 0, 16000)
	height_label.text = "STAGE %d / 2,000 m   ·   TOTAL %d / 16,000 m" % [stage_meters, total_meters]
	var names := ["COMPOST FLOOR", "WORM CITY", "FUNGAL FOREST", "ROOT ZONE", "GARDEN BED", "POND EDGE", "GREENHOUSE", "SUNFLOWER CANOPY"]
	var difficulties := ["EASY", "NORMAL", "HARD", "SUPER HARD", "EXTRA HARD", "CRAZY HARD", "IMPOSSIBLE", "NO WAY BRUH"]
	level_label.text = "LEVEL %d · %s · %s" % [current_level, difficulties[current_level - 1], names[current_level - 1]]
	if height >= LEVELS * LEVEL_HEIGHT - 120.0:
		_show_win()
		return
	# Rescue is free: one charge is banked automatically every 2,000 m
	# (see _on_checkpoint), and only triggers during a fall.
	if current_level >= 2 and rescue_charges > 0 and player.velocity.y > 120.0 and Input.is_action_just_pressed("rescue"):
		_start_rescue()
	if rescue_active:
		player.velocity.y = move_toward(player.velocity.y, -1180.0, 3800.0 * delta)
		if player.position.y <= rescue_target_y or player.is_on_ceiling():
			_end_rescue()
	if player.is_on_floor() and rescue_active:
		_end_rescue()
	if player.position.y > WORLD_BOTTOM + 500:
		_respawn()
	status_timer -= delta
	status_label.modulate.a = clamp(status_timer, 0.0, 1.0)

func _on_obstacle_hit(body: Node2D) -> void:
	if body != player or obstacle_hit_cooldown > 0.0:
		return
	obstacle_hit_cooldown = 0.8
	if shield_charges > 0:
		shield_charges -= 1
		status_label.text = "🛡️ SHIELD ABSORBED THE HIT! (%d LEFT)" % shield_charges
		status_timer = 1.6
	else:
		combo_streak = 0
		combo_timer = 0.0
		combo_label.text = ""
		player.velocity = Vector2(-player.facing * 260.0, -320.0)
		status_label.text = "OUCH! COMBO LOST"
		status_timer = 1.4

func _start_rescue() -> void:
	rescue_charges -= 1
	rescue_active = true
	player.boosting = true
	rescue_start_y = player.position.y
	rescue_target_y = player.position.y - 1850.0
	player.velocity.y = -1250.0
	ability_label.text = "RESCUE BOOST · ACTIVE"
	ability_label.add_theme_color_override("font_color", Color.WHITE)

func _end_rescue() -> void:
	rescue_active = false
	player.boosting = false
	player.velocity.y = min(player.velocity.y, -260.0)
	ability_label.text = "BOOSTS SAVED: %d" % rescue_charges
	ability_label.add_theme_color_override("font_color", Color("eaffb5") if rescue_charges > 0 else Color(0.6,0.6,0.6))

func _on_checkpoint(body: Node2D, marker: Area2D) -> void:
	if body != player:
		return
	var level := int(marker.get_meta("level"))
	if level > checkpoint_level:
		checkpoint_level = level
		checkpoint = Vector2(marker.position.x, marker.position.y - 90)
		# A free rescue boost is banked every time a new 2,000 m stage is
		# reached (levels 2-8), so a flawless run banks 7 by the top.
		if level >= 2:
			rescue_charges += 1
		ability_label.text = "BOOSTS SAVED: %d" % rescue_charges if level >= 2 else "UNLOCKS AT LEVEL 2"
		status_text = "LEVEL %d CHECKPOINT SAVED · +1 RESCUE BOOST (%d SAVED)" % [level, rescue_charges]
		status_label.text = status_text
		status_timer = 3.5
		_show_stage_transition(level)

func _respawn() -> void:
	player.position = checkpoint
	player.velocity = Vector2.ZERO
	rescue_active = false
	player.boosting = false
	combo_streak = 0
	combo_timer = 0.0
	combo_label.text = ""
	magnet_timer = 0.0
	slowfall_timer = 0.0
	ability_label.text = "BOOSTS SAVED: %d" % rescue_charges if checkpoint_level >= 2 else "UNLOCKS AT LEVEL 2"
	status_label.text = "RETURNED TO LEVEL %d CHECKPOINT" % checkpoint_level
	status_timer = 3.0

func _show_win() -> void:
	won = true
	rescue_active = false
	player.boosting = false
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	_record_leaderboard_entry(Time.get_ticks_msec() / 1000.0 - run_start_time)
	win_overlay.show()

func _start_music() -> void:
	# Full-length original instrumental asset with multiple sections.
	music_player = AudioStreamPlayer.new()
	music_player.stream = load("res://audio/terracast_garden_groove.wav")
	music_player.volume_db = -10.0
	add_child(music_player)
	music_player.finished.connect(func(): music_player.play())
	music_player.play()

func _toggle_mute() -> void:
	muted = not muted
	music_player.volume_db = -80.0 if muted else -10.0
	mute_button.text = "🔇 MUTED" if muted else "🔊 MUSIC"
