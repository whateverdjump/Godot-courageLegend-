extends Enemy

@onready var floor_ray_cast: RayCast2D = $Character/FloorRayCast
@onready var wall_ray_cast: RayCast2D = $Character/WallRayCast
@onready var player_ray_cast: RayCast2D = $Character/PlayerRayCast
@onready var see_player_timer: Timer = $seePlayerTimer
@onready var attack_ray_cast: RayCast2D = $Character/AttackRayCast
@onready var attack_interval_timer: Timer = $attackIntervalTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var stats: Node = $Stats
enum State {
	IDLE,
	WALK,
	RUN,
	ATTACK1,
	ATTACK2,
	HURT,
	DEATH
}

var pending_demage: Demage
var getLastDir := 1.0

const MOVE_SPEED := 150.0
const CAN_ATTACK := [State.ATTACK1, State.ATTACK2]
const KNOCKBACK_AMOUNT := 300.0

func tick_physics(state: State, delta: float) -> void:
	match state:
		State.IDLE, State.HURT, State.DEATH:
			move(0, delta)
		State.WALK:
			move(MOVE_SPEED/3, delta)
		State.RUN:
			if player_ray_cast.is_colliding():
				see_player_timer.start()
			if not floor_ray_cast.is_colliding() or wall_ray_cast.is_colliding():
				presend_dir *= -1
			move(MOVE_SPEED, delta)

func get_next_state(state: State) -> int:

	if attack_ray_cast.is_colliding() and not state in CAN_ATTACK and attack_interval_timer.time_left == 0:
		attack_interval_timer.start()
		return State.ATTACK1
	if pending_demage:
		print('状态', state, pending_demage)
		return State.HURT
	if stats.health == 0:
		return State.DEATH

	match state:
		State.IDLE:
			if attack_ray_cast.is_colliding() and attack_interval_timer.time_left > 0 and player_ray_cast.is_colliding():
				return state
			if player_ray_cast.is_colliding():
				return State.RUN
			if state_ststem.awaitTimer > 3:
				return State.WALK
		State.WALK:
			if player_ray_cast.is_colliding():
				return State.RUN
			if not floor_ray_cast.is_colliding() or wall_ray_cast.is_colliding():
				return State.IDLE
		State.RUN:
			if not player_ray_cast.is_colliding() and see_player_timer.is_stopped():
				return State.WALK
		State.ATTACK1:
			if not animation_player.is_playing() and attack_ray_cast.is_colliding():
				return State.ATTACK2
			if not animation_player.is_playing():
				return State.RUN
		State.ATTACK2:
			if not animation_player.is_playing():
				return State.IDLE
		State.HURT:
			if not animated_sprite_2d.is_playing():
				return State.RUN

	return state
	
func change_state(form: State, to: State) -> void:
	match to:
		State.IDLE:
			animated_sprite_2d.play("idle")
			if wall_ray_cast.is_colliding():
				presend_dir *= -1
		State.WALK:
			animated_sprite_2d.play("walk")
			if not floor_ray_cast.is_colliding():
				presend_dir *= -1
				floor_ray_cast.force_raycast_update()
		State.RUN:
			animated_sprite_2d.play("run")
		State.ATTACK1:
			animation_player.play("attack1")
		State.ATTACK2:
			animation_player.play("attack2")
		State.HURT:
			animated_sprite_2d.play("hurt")
			stats.health -= pending_demage.amount
			var retreat_dir = pending_demage.source.global_position.direction_to(global_position)
			velocity = retreat_dir * KNOCKBACK_AMOUNT
			
			if retreat_dir.x > 0:
				presend_dir = direction.LEFT
			else:
				presend_dir = direction.RIGHT
			pending_demage = null

		State.DEATH:
			animation_player.play("death")

func die() -> void:
	print('死完了')
	queue_free()

func _on_hurtbox_hurt(hitbox: Hitbox) -> void:
	pending_demage = Demage.new()
	pending_demage.amount = 1
	pending_demage.source = hitbox.owner
