class_name Player
extends CharacterBody2D
@onready var character: Marker2D = $Character
@onready var animated_sprite_2d: AnimatedSprite2D = $Character/AnimatedSprite2D
@onready var state_ststem: StateStstem = $StateStstem
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var wall_raycast: RayCast2D = $Character/WallRaycast
@onready var back_wall_raycast: RayCast2D = $Character/BackWallRaycast
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var attack_timer: Timer = $AttackTimer
@onready var stats: Stats = $Stats
@onready var ineffective_timer: Timer = $IneffectiveTimer
@onready var jump_request_timer: Timer = $JumpRequestTimer
enum State {
	IDLE,
	RUN,
	JUMP,
	JUMPFALLINBETWEEN,
	FALL,
	WALLSLIDE,
	WALLJUMP,
	ATTACK1,
	ATTACK2,
	HIT
}

var pending_demage: Demage
var gravity := ProjectSettings.get_setting("physics/2d/default_gravity") as float

const IS_FLOOR := [State.IDLE, State.RUN]
const IS_FALL := [State.JUMPFALLINBETWEEN, State.FALL]
const MOVE_SPEED := 200.0
const JUMP_HEIGHT := -320.0
const WALL_JUMP_HEIGHT := Vector2(1000, -350.0)
const FLOOR_ACCELERATION := MOVE_SPEED / 0.1
const AIR_ACCELERATION := MOVE_SPEED / 0.02
const SLIDE_SPEED := 0.5
# 被击中后移动的距离
const KNOCKBACK_AMOUNT := 200 

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("jump"):
		jump_request_timer.start()
	if Input.is_action_just_pressed("attack"):
		attack_timer.start()

func tick_physics(state: State, delta: float) -> void:
	match state:
		State.IDLE:
			move(gravity, delta, true)
		State.RUN:
			move(gravity, delta, true)
		State.JUMP:
			move(gravity, delta, true)
		State.JUMPFALLINBETWEEN, State.FALL:
			move(gravity, delta, true)
		State.WALLSLIDE:
			slide(SLIDE_SPEED, delta, false)
		State.WALLJUMP:
			move(gravity, delta, true)
		State.HIT:
			move(gravity, delta, false)

func move(gravity: float, delta: float, isMove: bool) -> void:
	var dir = Input.get_axis("move_left","move_right")
	var ACCELERATION := FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	if dir:
		character.scale.x = dir
	if isMove:
		velocity.x = move_toward(velocity.x, MOVE_SPEED * dir, ACCELERATION * delta)
	velocity.y += gravity * delta
	move_and_slide()
func slide(gravity: float, delta: float, isMove: bool) -> void:
	var dir = Input.get_axis("move_left","move_right")
	if dir:
		character.scale.x = -dir
	if isMove:
		velocity.x = MOVE_SPEED * dir
	if state_ststem.awaitTimer < 0.5:
		velocity.y += gravity
	else:
		velocity.y += gravity * delta
	move_and_slide()
	
func get_next_state(state: State) -> int:
	var dir = Input.get_axis("move_left","move_right")
	var can_run = is_on_floor() and dir
	
	if pending_demage:
		return State.HIT
#	郊狼时间
	var can_jump = is_on_floor() or coyote_timer.time_left > 0
	var isJump = can_jump and jump_request_timer.time_left > 0
	if isJump:
		return State.JUMP
	if state in IS_FALL and wall_raycast.is_colliding() and dir:
		return State.WALLSLIDE
	if velocity.y > 0 and not state in IS_FALL and state != State.WALLSLIDE:
		return State.JUMPFALLINBETWEEN
#		当吸附在墙上的时候且不输入方向键, 则进入下落状态
	if state == State.WALLSLIDE and not dir:
		return State.JUMPFALLINBETWEEN

	match state:
		State.IDLE:
			if attack_timer.time_left > 0:
				return State.ATTACK1
			if can_run:
				return State.RUN
		State.RUN:
			if attack_timer.time_left > 0:
				return State.ATTACK1
			if not can_run:
				return State.IDLE
		State.JUMP:
			if is_on_floor():
				return State.IDLE
		State.JUMPFALLINBETWEEN:
			if not animated_sprite_2d.is_playing():
				return State.FALL
			if is_on_floor():
				return State.IDLE
		State.FALL:
			if is_on_floor():
				return State.IDLE
		State.WALLSLIDE:
			if jump_request_timer.time_left > 0:
				return State.WALLJUMP
			if is_on_floor():
				return State.IDLE
			if state_ststem.awaitTimer > 0 and not back_wall_raycast.is_colliding():
				return State.IDLE

		State.WALLJUMP:
			if is_on_floor():
				return State.IDLE
		State.ATTACK1:
			if not animation_player.is_playing() and attack_timer.time_left > 0:
				return State.ATTACK2
			if not animation_player.is_playing():
				return State.IDLE
		State.ATTACK2:
			if not animation_player.is_playing():
				return State.IDLE
		State.HIT:
			if not animation_player.is_playing():
				return State.IDLE
	
	return state_ststem.KEEP_CURRENT
	
func change_state(form: State, to: State) -> void:
	print('当前状态', to, is_on_floor())
	if form in IS_FLOOR and to != State.JUMP:
		coyote_timer.start()
	match to:
		State.IDLE:
			animated_sprite_2d.play("idle")
		State.RUN:
			animated_sprite_2d.play("run")
		State.JUMP:
			coyote_timer.stop()
			jump_request_timer.stop()
			velocity.y = JUMP_HEIGHT
			animated_sprite_2d.play("jump")
		State.JUMPFALLINBETWEEN:
			animated_sprite_2d.play("jump_fall_inbet_ween")
		State.FALL:
			animated_sprite_2d.play("fall")
		State.WALLSLIDE:
			animated_sprite_2d.play("wall_slide")
		State.WALLJUMP:
			jump_request_timer.stop()
			velocity = WALL_JUMP_HEIGHT
			velocity.x *= get_wall_normal().x
			character.scale.x = -1 if velocity.x > 0 else 1
			animated_sprite_2d.play("jump")
		State.ATTACK1:
			animation_player.play("attack1")
		State.ATTACK2:
			animation_player.play("attack2")
		State.HIT:
			animation_player.play("hurt")
			stats.health -= pending_demage.amount
			var retreat_dir = pending_demage.source.global_position.direction_to(global_position)

			velocity = retreat_dir * KNOCKBACK_AMOUNT
			pending_demage = null

func _on_hurtbox_hurt(hitbox: Hitbox) -> void:
	if ineffective_timer.time_left > 0:
		return
	ineffective_timer.start()
	pending_demage = Demage.new()
	pending_demage.amount = 1
	pending_demage.source = hitbox.owner
