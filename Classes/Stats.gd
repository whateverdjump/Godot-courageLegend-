class_name Stats
extends Node

signal healyh_changed

@export var max_health := 3.0

@onready var health := max_health:
	set(v):
		v = clamp(v, 0.0, max_health)
		if v == health:
			return
		health = v
