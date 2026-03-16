# scripts/derelict/enemy_base.gd
extends CharacterBody2D

@export var max_hp: int = 3
@export var move_speed: float = 40.0
@export var loot_resource: String = "scrap"
@export var loot_amount: int = 1

var _hp: int = 0

func _ready() -> void:
	_hp = max_hp

func take_damage(amount: int) -> void:
	_hp -= amount
	if _hp <= 0:
		_die()

func _die() -> void:
	var run = get_tree().get_root().find_child("DerelictRun", true, false)
	if run:
		run.add_loot(loot_resource, loot_amount)
	queue_free()
