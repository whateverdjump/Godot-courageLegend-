class_name StateStstem
extends Node2D

var status_same := -1
var state_value := -1:
	set(v):
		if state_value == v:
			return
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
		if next == state_value:
			break
		#print('状态切换', next, state_value)
		state_value = next

		awaitTimer = 0
	owner.tick_physics(state_value ,delta)
