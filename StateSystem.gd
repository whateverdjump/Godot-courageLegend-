class_name StateStstem
extends Node2D

const KEEP_CURRENT := -1
var state_value := -1:
	set(v):
		owner.change_state(state_value, v)
		state_value = v
		
var awaitTimer:float = 0

func _ready() -> void:
#	需等待父元素的ready走完再执行
	await owner.ready
	state_value = 0
	
func _physics_process(delta: float) -> void:
	awaitTimer+=delta
	while true:
		var next := owner.get_next_state(state_value) as int
		if next == KEEP_CURRENT:
			break
		state_value = next

		awaitTimer = 0
	owner.tick_physics(state_value ,delta)
