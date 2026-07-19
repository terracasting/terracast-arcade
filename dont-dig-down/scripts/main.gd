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
var rescue_ready := false
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
var character_menu: ColorRect
var win_overlay: ColorRect
var stage_overlay: ColorRect
var stage_overlay_title: Label
var stage_overlay_detail: Label
var game_started := false
var won := false
var coins := 0
const BOOST_COST := 20
var checkpoint_markers: Array[Area2D] = []
var rng := RandomNumberGenerator.new()

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
		# Soft shadow and a compact, readable worm made from overlapping segments.
		_draw_soft_ellipse(Vector2(0, 39), Vector2(35, 10), Color(0, 0, 0, 0.28))
		var stretch: float = 1.0 + minf(absf(velocity.y) / 2100.0, 0.18) - squash * 0.12
		for i in range(5, -1, -1):
			var y: float = 28.0 - i * 13.0 * stretch
			var radius: float = 20.0 - absi(i - 3) * 1.25
			var c: Color = body_color.lerp(Color.WHITE, 0.10 + float(i) / 20.0)
			draw_circle(Vector2(0, y), radius, c)
			draw_arc(Vector2(0, y), radius - 2, 0, TAU, 28, Color(0.35, 0.07, 0.035, 0.32), 2.0)
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
		if boosting:
			var glow := Color(0.58, 1.0, 0.42, 0.72)
			var wing_l := PackedVector2Array([Vector2(-13,-15),Vector2(-68,-54),Vector2(-56,4),Vector2(-12,11)])
			var wing_r := PackedVector2Array([Vector2(13,-15),Vector2(68,-54),Vector2(56,4),Vector2(12,11)])
			draw_colored_polygon(wing_l, glow)
			draw_colored_polygon(wing_r, glow)
			draw_polyline(wing_l, Color("eaffbb"), 3.0)
			draw_polyline(wing_r, Color("eaffbb"), 3.0)

	func _draw_soft_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
		var pts := PackedVector2Array()
		for i in 32:
			var a: float = TAU * i / 32.0
			pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
		draw_colored_polygon(pts, color)

class MovingPlatform extends AnimatableBody2D:
	var base_position := Vector2.ZERO
	var move_amplitude := 90.0
	var move_speed := 1.2
	var move_phase := 0.0
	var elapsed := 0.0

	func _physics_process(delta: float) -> void:
		elapsed += delta
		position = base_position + Vector2(sin(elapsed * move_speed + move_phase) * move_amplitude, 0)

class CoinVisual extends Node2D:
	func _draw() -> void:
		# A round, high-contrast gold coin that does not depend on emoji fonts.
		draw_circle(Vector2(3, 5), 35, Color(0, 0, 0, 0.30))
		draw_circle(Vector2.ZERO, 35, Color("a86408"))
		draw_circle(Vector2.ZERO, 31, Color("ffd34e"))
		draw_circle(Vector2.ZERO, 24, Color("e7a91d"))
		draw_arc(Vector2.ZERO, 27, 0, TAU, 48, Color("fff2a3"), 3.0)
		# Simple curled-worm emblem stamped into the center.
		draw_arc(Vector2(-2, 1), 12, -0.55, 4.7, 28, Color("7b4a08"), 5.0)
		draw_circle(Vector2(9, -7), 3.2, Color("7b4a08"))
		# Metallic shine.
		draw_arc(Vector2(-5, -5), 21, 3.5, 5.1, 18, Color(1, 1, 0.82, 0.85), 4.0)

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
	var back := Backdrop.new()
	back.z_index = -20
	add_child(back)
	_build_world()
	_build_player()
	_build_ui()
	_start_music()

func _setup_input() -> void:
	_add_keys("move_left", [KEY_A, KEY_LEFT])
	_add_keys("move_right", [KEY_D, KEY_RIGHT])
	_add_keys("jump", [KEY_SPACE, KEY_W, KEY_UP])
	_add_keys("rescue", [KEY_Q, KEY_SHIFT])
	_add_keys("restart", [KEY_R])
	_add_keys("buy_boost", [KEY_B])

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
			var moving_interval: int = maxi(7, 20 - level * 2)
			var is_moving := row >= 50 and row < 95 and row % moving_interval == 0 and not mandatory_double
			_add_platform(Vector2(x, y), Vector2(width, 52), false, platform_style, is_moving, level, row)
			var obstacle_spacing: int = maxi(3, 7 - level)
			if not tiny_stairs and not narrow_crossing and not mandatory_double and (row % obstacle_spacing == 1 or row % 5 == 2):
				_add_obstacle(Vector2(x + (-70.0 if row % 2 == 0 else 70.0), y - 72.0), (row + level) % 5)
			if row % 5 == 0:
				_add_coin(Vector2(x, y - 72))
		if level < LEVELS - 1:
			var boundary_step: int = (level + 1) * 100
			var next_x: float = 3500.0 + 2900.0 * sin(float(boundary_step) * 0.12)
			var checkpoint_y: float = base_y - LEVEL_HEIGHT
			_add_platform(Vector2(next_x, checkpoint_y), Vector2(900, 64), true)
			_add_checkpoint(Vector2(next_x, checkpoint_y - 78), level + 2)
	# A broad finish garden above the sixth biome.
	_add_platform(Vector2(3500, WORLD_BOTTOM - LEVELS * LEVEL_HEIGHT), Vector2(2200, 76), true)

func _add_platform(pos: Vector2, size: Vector2, safe: bool, style: int = 0, moving: bool = false, stage: int = 0, row: int = 0) -> void:
	var body: Node2D
	if moving:
		var mover := MovingPlatform.new()
		mover.base_position = pos
		mover.move_amplitude = 35.0 + float(stage) * 20.0
		mover.move_speed = 0.72 + float(stage) * 0.11
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
		body_color = Color("2f9eaa")
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
		moss.default_color = Color("73e4ff")
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

func _add_obstacle(pos: Vector2, style: int) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	var sizes := [Vector2(82,96),Vector2(110,82),Vector2(72,126),Vector2(120,76),Vector2(88,104)]
	var colors := [Color("77848b"),Color("9a6938"),Color("d46b46"),Color("725137"),Color("8c9f45")]
	var size: Vector2 = sizes[style]
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
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
	else: # Sprout
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
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 32
	shape.shape = circle
	coin.add_child(shape)
	coin.add_child(CoinVisual.new())
	coin.body_entered.connect(_collect_coin.bind(coin))
	add_child(coin)

func _collect_coin(body: Node2D, coin: Area2D) -> void:
	if body != player or not is_instance_valid(coin):
		return
	coins += 1
	coin_label.text = "COINS: %d" % coins
	status_label.text = "COIN COLLECTED · %d / %d FOR AN EXTRA BOOST" % [coins, BOOST_COST]
	status_timer = 1.4
	coin.queue_free()

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
	hint_label = _label(Vector2(50,995), 24, Color(1,1,1,0.82), "A/D or arrows: move     SPACE: high jump     Q or SHIFT: rescue boost     R: checkpoint")
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
	ability_label = _label(Vector2(0,184), 26, Color("eaffb5"), "RESCUE BOOST · READY")
	ability_label.size = Vector2(230,70)
	ability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rescue_button.add_child(ability_label)
	var wings := _label(Vector2(60,40), 72, Color.WHITE, "❧")
	wings.size = Vector2(110,100)
	wings.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rescue_button.add_child(wings)
	_build_character_menu(layer)
	_build_stage_overlay(layer)
	_build_win_overlay(layer)
	_build_touch_controls(layer)

func _touch_button(layer: CanvasLayer, label_text: String, button_size: Vector2) -> Button:
	var button := Button.new()
	button.text = label_text
	button.size = button_size
	button.modulate = Color(1, 1, 1, 0.68)
	button.focus_mode = Control.FOCUS_NONE
	button.z_index = 100
	button.add_theme_font_size_override("font_size", 28)
	layer.add_child(button)
	return button

func _bind_hold_button(button: Button, action: StringName) -> void:
	button.button_down.connect(func() -> void: Input.action_press(action))
	button.button_up.connect(func() -> void: Input.action_release(action))
	button.tree_exiting.connect(func() -> void: Input.action_release(action))

func _build_touch_controls(layer: CanvasLayer) -> void:
	# Large thumb targets stay at the screen edges while leaving the center clear.
	var left := _touch_button(layer, "◀", Vector2(116, 104))
	var right := _touch_button(layer, "▶", Vector2(116, 104))
	var jump_button := _touch_button(layer, "JUMP", Vector2(138, 112))
	var boost_button := _touch_button(layer, "BOOST", Vector2(130, 96))

	var layout_controls := func() -> void:
		var viewport_size := get_viewport().get_visible_rect().size
		var portrait := viewport_size.y > viewport_size.x
		var bottom_y := viewport_size.y - 128.0
		left.position = Vector2(24, bottom_y)
		right.position = Vector2(154, bottom_y)
		jump_button.position = Vector2(viewport_size.x - 162.0, viewport_size.y - 136.0)
		if portrait:
			# Stack BOOST well above JUMP when horizontal room is limited.
			boost_button.position = Vector2(viewport_size.x - 158.0, viewport_size.y - 252.0)
		else:
			# In landscape, keep BOOST beside JUMP with a generous thumb gap.
			boost_button.position = Vector2(viewport_size.x - 322.0, viewport_size.y - 128.0)

	layout_controls.call()
	get_viewport().size_changed.connect(layout_controls)
	_bind_hold_button(left, "move_left")
	_bind_hold_button(right, "move_right")
	_bind_hold_button(jump_button, "jump")
	boost_button.pressed.connect(func() -> void:
		Input.action_press("rescue")
		await get_tree().process_frame
		Input.action_release("rescue")
	)

func _build_character_menu(layer: CanvasLayer) -> void:
	player.set_physics_process(false)
	character_menu = ColorRect.new()
	character_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	character_menu.color = Color(0.035,0.045,0.025,0.97)
	layer.add_child(character_menu)
	var title := _label(Vector2(480,105), 64, Color("eaffb5"), "CHOOSE YOUR CLIMBER")
	title.size = Vector2(960,90)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	character_menu.add_child(title)
	var subtitle := _label(Vector2(510,195), 28, Color("f2e4b6"), "Eight separate stages · 100 route platforms each · 16,000 meters total")
	subtitle.size = Vector2(900,55)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	character_menu.add_child(subtitle)
	var choices := [
		["RED WIGGLER", Color("d95745")], ["EURO NIGHTCRAWLER", Color("7c65b8")],
		["GOLDEN COMPOSTER", Color("d7a83e")], ["FOREST WORM", Color("4f9b65")],
		["BUBBLEGUM WORM", Color("e572a5")], ["MIDNIGHT WORM", Color("3e5f85")]
	]
	for i in choices.size():
		var button := Button.new()
		button.position = Vector2(500 + (i % 2) * 470, 300 + int(i / 2) * 170)
		button.size = Vector2(420,125)
		button.text = "●   PLAY AS %s" % choices[i][0]
		button.add_theme_font_size_override("font_size", 27)
		button.add_theme_color_override("font_color", (choices[i][1] as Color).lightened(0.35))
		button.pressed.connect(_select_character.bind(choices[i][0], choices[i][1], i))
		character_menu.add_child(button)

func _select_character(character_name: String, color: Color, variant: int) -> void:
	player.set("body_color", color)
	player.set("character_variant", variant)
	player.queue_redraw()
	character_menu.hide()
	game_started = true
	player.set_physics_process(true)
	status_label.text = "%s BEGINS THE 16,000 m CLIMB!" % character_name
	status_timer = 4.0

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
	var continue_button := Button.new()
	continue_button.position = Vector2(710,575)
	continue_button.size = Vector2(500,110)
	continue_button.text = "ENTER NEXT STAGE"
	continue_button.add_theme_font_size_override("font_size", 33)
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
	var again := Button.new()
	again.position = Vector2(730,560)
	again.size = Vector2(460,105)
	again.text = "CLIMB AGAIN"
	again.add_theme_font_size_override("font_size", 34)
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

func _physics_process(delta: float) -> void:
	if not game_started or won:
		return
	if Input.is_action_just_pressed("restart"):
		_respawn()
	if Input.is_action_just_pressed("buy_boost") and not rescue_ready and coins >= BOOST_COST:
		coins -= BOOST_COST
		rescue_ready = true
		coin_label.text = "COINS: %d" % coins
		ability_label.text = "RESCUE BOOST · READY"
		ability_label.add_theme_color_override("font_color", Color("eaffb5"))
		status_label.text = "EXTRA RESCUE BOOST PURCHASED!"
		status_timer = 2.5
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
	# Rescue becomes available after reaching Level 2, and only triggers during a fall.
	if current_level >= 2 and rescue_ready and player.velocity.y > 120.0 and Input.is_action_just_pressed("rescue"):
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

func _start_rescue() -> void:
	rescue_ready = false
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
	ability_label.text = "RESCUE BOOST · USED"
	if coins >= BOOST_COST:
		ability_label.text = "PRESS B · BUY BOOST (%d)" % BOOST_COST
	ability_label.add_theme_color_override("font_color", Color(0.6,0.6,0.6))

func _on_checkpoint(body: Node2D, marker: Area2D) -> void:
	if body != player:
		return
	var level := int(marker.get_meta("level"))
	if level > checkpoint_level:
		checkpoint_level = level
		checkpoint = Vector2(marker.position.x, marker.position.y - 90)
		rescue_ready = level >= 2
		ability_label.text = "RESCUE BOOST · READY" if rescue_ready else "UNLOCKS AT LEVEL 2"
		status_text = "LEVEL %d CHECKPOINT SAVED · RESCUE BOOST EARNED!" % level
		status_label.text = status_text
		status_timer = 3.5
		_show_stage_transition(level)

func _respawn() -> void:
	player.position = checkpoint
	player.velocity = Vector2.ZERO
	rescue_active = false
	player.boosting = false
	rescue_ready = checkpoint_level >= 2
	ability_label.text = "RESCUE BOOST · READY" if rescue_ready else "UNLOCKS AT LEVEL 2"
	status_label.text = "RETURNED TO LEVEL %d CHECKPOINT" % checkpoint_level
	status_timer = 3.0

func _show_win() -> void:
	won = true
	rescue_active = false
	player.boosting = false
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	win_overlay.show()

func _start_music() -> void:
	# Full-length original instrumental asset with multiple sections.
	var music := AudioStreamPlayer.new()
	music.stream = load("res://audio/terracast_garden_groove.wav")
	music.volume_db = -10.0
	add_child(music)
	music.finished.connect(func(): music.play())
	music.play()
