extends Area2D

@export var label_text: String = ""

func _ready() -> void:
	if has_meta("label_text"):
		label_text = get_meta("label_text")
	$Label.text = label_text
	$Label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		$Label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		$Label.visible = false
