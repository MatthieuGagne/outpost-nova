extends Area2D

@export var target_area: String = ""

func _ready() -> void:
	if has_meta("target_area"):
		target_area = get_meta("target_area")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		get_tree().get_root().get_node("Main").go_to_area(target_area)
