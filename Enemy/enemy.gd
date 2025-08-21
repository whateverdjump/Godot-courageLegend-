class_name Enemy
extends CharacterBody2D

@onready var character: Marker2D = $Character
@onready var animated_sprite_2d: AnimatedSprite2D = $Character/AnimatedSprite2D
@onready var state_ststem: StateStstem = $StateStstem

enum direction {
	LEFT = -1,
	RIGHT = 1
}

var gravity := ProjectSettings.get_setting("physics/2d/default_gravity") as float

@export var presend_dir: int = direction.LEFT:
	set(v):
		presend_dir = v
		if not is_inside_tree():
			await ready
		character.scale.x = v


func move(speed: float, delta: float) -> void:	
	velocity.x = speed * presend_dir
	velocity.y += gravity * delta
	move_and_slide()
