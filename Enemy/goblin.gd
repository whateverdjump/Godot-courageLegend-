extends Enemy

@onready var floor_ray_cast: RayCast2D = $Character/FloorRayCast
@onready var wall_ray_cast: RayCast2D = $Character/WallRayCast
@onready var player_ray_cast: RayCast2D = $Character/PlayerRayCast
@onready var see_player_timer: Timer = $seePlayerTimer
@onready var attack_ray_cast: RayCast2D = $Character/AttackRayCast
@onready var attack_interval_timer: Timer = $attackIntervalTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

enum State {
	IDLE,
	WALK,
	RUN,
	ATTACK1,
	ATTACK2
}


var getLastDir := 1.0

const MOVE_SPEED := 150.0
const CAN_ATTACK := [State.ATTACK1, State.ATTACK2]

func tick_physics(state: State, delta: float) -> void:
	match state:
		State.IDLE:
			move(0, delta)
		State.WALK:
			move(MOVE_SPEED/3, delta)
		State.RUN:
			move(MOVE_SPEED, delta)
			if player_ray_cast.is_colliding():
				see_player_timer.start()
			if not floor_ray_cast.is_colliding() or wall_ray_cast.is_colliding():
				presend_dir *= -1
			
func get_next_state(state: State) -> int:
	if attack_ray_cast.is_colliding() and not state in CAN_ATTACK and attack_interval_timer.time_left == 0:
		attack_interval_timer.start()
		print(attack_interval_timer.time_left, '这个值')
		return State.ATTACK1
	
	match state:
		State.IDLE:
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
			if not animation_player.is_playing() and see_player_timer.is_stopped():
				return State.ATTACK2
		State.ATTACK2:
			if not animation_player.is_playing():
				return State.IDLE
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


func _on_hurtbox_hurt(hitbox: Hitbox) -> void:
	print('Ouch!!!哥布林被',hitbox.owner.name, '击中了')
