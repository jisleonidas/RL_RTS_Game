extends CharacterBody2D


const SPEED = 40.0
# const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var health: int = 100
var type: String = "swordsman"

var is_selected: bool = false
var has_target: bool = false
var target_position: Vector2 = global_position

var friendly: bool = true

var chasing: bool = false
var attacking: bool = false
var defending: bool = false
var target_unit: Node = null

var death_counter: int = 0
var attack_cooldown: int = 0
var defend_cooldown: int = 03

func _ready():
	target_position = global_position
	add_to_group("units")
	var fill_style = $HealthBar.get("theme_override_styles/fill")
	if fill_style:
		$HealthBar.set("theme_override_styles/fill", fill_style.duplicate())
	if friendly:
		add_to_group("friendly")
		$HealthBar.get("theme_override_styles/fill").bg_color = Color.GREEN
	else:
		add_to_group("enemy")
		$HealthBar.get("theme_override_styles/fill").bg_color = Color.RED
		
func _physics_process(delta: float) -> void:
	if chasing:
		if is_instance_valid(target_unit):
			target_position = target_unit.global_position
		else:
			chasing = false
			target_unit = null
	if (has_target or chasing) and not attacking:
		$AnimatedSprite2D.animation = "walk"
		var direction = (target_position - global_position)
		if direction.length() > 1:
			velocity = direction.normalized() * SPEED
		else:
			$AnimatedSprite2D.animation = "idle"
			velocity = Vector2.ZERO
			has_target = false
	elif attacking:
		$AnimatedSprite2D.animation = "attack"
		velocity = Vector2.ZERO
	elif defending:
		$AnimatedSprite2D.animation = "defend"
		velocity = Vector2.ZERO
	else:
		if health > 50:
			$AnimatedSprite2D.animation = "idle"
		else:
			if health > 0:
				$AnimatedSprite2D.animation = "hurt"
			else:
				$AnimatedSprite2D.animation = "death"
				if death_counter > 300:
					queue_free()
		velocity = Vector2.ZERO
	move_and_slide()

	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if collision:
			var collider = collision.get_collider()
			if collider.is_in_group("units") and (friendly != collider.friendly):
				if chasing == true:
					attacking = true
				else:
					if health == 0:
						defending = false
						return
					defending = true
					if collider.type == "swordsman":
						health -= 0.1

	## Add the gravity.
	#if not is_on_floor():
		#velocity += get_gravity() * delta
	 
	## Handle jump.  
	#if Input.is_action_just_pressed("ui_accept"): # and is_on_floor():
		#velocity.y = JUMP_VELOCITY
#
	## Get the input direction and handle the movement/deceleration.
	## As good practice, you should replace UI actions with custom gameplay actions.
	#var direction := Input.get_axis("ui_left", "ui_right")
	#if direction:
		#velocity.x = direction * SPEED
	#else:
		#velocity.x = move_toward(velocity.x, 0, SPEED)

func _process(delta: float) -> void:
	$HealthBar.value = health
	if health == 0:
		death_counter += 1

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
	chasing = true

func move_to(pos: Vector2) -> void:
	chasing = false
	attacking = false
	print("move to called")
	target_position = pos
	has_target = true
