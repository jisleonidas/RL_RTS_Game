extends CharacterBody2D


const WALK_SPEED = 40.0
const RUN_SPEED = 80.0
# const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var health: float = 100.0
var type: String = "swordsman"

var is_selected: bool = false
var has_target: bool = false
var target_position: Vector2 = global_position

var friendly: bool = true

var state: String = "idle"
var target_unit: Node = null
var last_attacked: Node = null

var attacker_count:= 0

var death_counter: int = 0
var attack_cooldown: int = 0
var defend_cooldown: int = 03

var enemies_in_killzone: = []

var dead: bool = false
var id: int = 0

@export var websocket_url = "ws://localhost:8765"
var socket: = WebSocketPeer.new()

var ai: bool = false

func _ready():
	if ai:
		$RLTimer.timeout.connect(_on_timer_timeout)
		$RLTimer.start()
		
		var err = socket.connect_to_url(websocket_url)
		if err != OK:
			print("Unable to connect")
			set_process(false)
		else:
			# Wait for the socket to connect
			await get_tree().create_timer(2).timeout

			# Send data
			socket.send_text("Agent id: %d connected to server" % id)
			print("Agent id: %d connected to server" % id)

	target_position = global_position
	add_to_group("units")
	
	#$CollisionShape2D.body_entered.connect(_on_body_entered)
	#$CollisionShape2D.body_exited.connect(_on_body_exited)

	var fill_style = $HealthBar.get("theme_override_styles/fill")
	if fill_style:
		$HealthBar.set("theme_override_styles/fill", fill_style.duplicate())
	if friendly:
		add_to_group("friendly")
		$HealthBar.get("theme_override_styles/fill").bg_color = Color.GREEN
	else:
		add_to_group("enemy")
		$HealthBar.get("theme_override_styles/fill").bg_color = Color.RED

#func _on_body_entered(body: Node) -> void:
	#if body.is_in_group("units") and (friendly != body.friendly):
		#attacker_count += 1
		#if state == "idle":
			#state = "defend"
			#print("Started defending!")
#
#func _on_body_exited(body: Node) -> void:
	#if body.is_in_group("units") and (friendly != body.friendly):
		#attacker_count += 1
		#if attacker_count == 0 and state == "defend":
			#state = "idle"
			#print("Stopped defending!")
		
func _physics_process(delta: float) -> void:
	if dead:
		$AnimatedSprite2D.animation = "death"
		if death_counter > 125:
			queue_free()
		else:
			return

	if state in ["idle", "attack", "defend"]:
		stationary(state)
	elif state in ["walk", "run"]:
		move(state)
	elif state == "chase":
		chase()

	#var collision = move_and_collide(velocity*delta)
	#handle_collision(collision)
	move_and_slide()
	for i in range(get_slide_collision_count()):
		handle_collision(get_slide_collision(i))
	
func handle_collision(collision: KinematicCollision2D) -> void:
	if collision:
		var collider = collision.get_collider()
		print("Collider: ", collider)
		if collider.is_in_group("units") and (friendly != collider.friendly):
			if state == "chase":
				state = "attack"

func chase() -> void:
	if is_instance_valid(target_unit):
		target_position = target_unit.global_position
	else:
		target_unit = null
	move("walk")

func move(type: String) -> void:
	var direction = (target_position - global_position)

	var animation = null
	var speed = null

	if type == "walk":
		animation = "walk"
		speed = WALK_SPEED
	elif type == "run":
		animation = "run"
		speed = RUN_SPEED

	$AnimatedSprite2D.animation = animation
	if direction.length() > 1:
		velocity = direction.normalized() * speed
	else:
		$AnimatedSprite2D.animation = "idle"
		velocity = Vector2.ZERO
		state = "idle"

func stationary(type: String) -> void:
	if type == "idle" and health < 50:
			$AnimatedSprite2D.animation = "hurt"
	elif type in ["idle", "attack", "defend"]:
		$AnimatedSprite2D.animation = type
	velocity = Vector2.ZERO

func deselect_unit():
	is_selected = false
	$SelectionBox.hide_box()

func select_unit():
	get_tree().call_group("units", "deselect_unit")
	is_selected = true
	$SelectionBox.show_box(Vector2(36, 38))
	print("Unit selected")

func attack(unit: Node):
	print("Attacking unit: ", unit)
	target_unit = unit
	state = "chase"

func move_to(pos: Vector2) -> void:
	print("move to called")
	target_position = pos
	state = "walk"

func check_state(_state: String) -> bool:
	if state == _state:
		return true
	else:
		return false

func set_state(_state: String) -> void:
	if _state in ["idle", "move", "run", "chase", "attack", "defend"]:
		state = _state

func _process(delta: float) -> void:
	$HealthBar.value = health
	if health <= 0:
		dead = true
		death_counter += 1
	if state == "attack" and target_unit in enemies_in_killzone:
		damage(target_unit)
	
func damage(body: CharacterBody2D) -> void:
	if not is_instance_valid(body) or body.dead:
		if state == "attack":
			state = "idle"
		return

	var att = type
	var def = body.type

	var damage_points = 0.05
	if (att == "swordsman" and def == "swordsman"):
		damage_points = 0.05
	
	if body.state == "defend":
		damage_points *= 0.3
	body.health -= damage_points

func _on_killzone_body_entered(body: CharacterBody2D) -> void:
	if body.is_in_group("units") and (friendly != body.friendly):
		if body not in enemies_in_killzone:
			enemies_in_killzone.append(body)

func _on_killzone_body_exited(body: CharacterBody2D) -> void:
	if body in enemies_in_killzone:
		enemies_in_killzone.erase(body)
		if target_unit == body and state == "attack":
			state == "chase"

func _on_timer_timeout():
	var data = []

	for i in get_parent().get_children():
		if i.is_in_group("units") and (friendly != i.friendly):
			var agent = {}
			agent["null"] = false
			agent["id"] = i.id
			agent["type"] = i.type
			agent["health"] = i.health
			agent["friendly"] = i.friendly
			agent["state"] = i.state
			agent["global_position"] = {}
			agent["global_position"]["x"] = i.global_position.x
			agent["global_position"]["y"] = i.global_position.y
			data.append(agent)

	#while len(data) < 3:
		#var agent = {}
		#agent["null"] = true; agent["id"] = null; agent["type"] = null; agent["health"] = null;
		#agent["friendly"] = null; agent["state"] = null; agent["global_position"] = null
		#data.append(agent)
	
	var state = {}
	state["agent"] = id
	state["timestamp"] = Time.get_ticks_msec()
	state["data"] = data
	
	var json_string := JSON.stringify(state)
	socket.send_text(json_string)
	socket.poll()
