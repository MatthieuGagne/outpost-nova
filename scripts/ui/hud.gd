# scripts/ui/hud.gd
extends CanvasLayer

@onready var rations_label: Label = $HBoxContainer/RationsLabel
@onready var parts_label: Label = $HBoxContainer/PartsLabel
@onready var energy_label: Label = $HBoxContainer/EnergyLabel

func _ready() -> void:
	GameState.resource_changed.connect(_on_resource_changed)
	_refresh_all()

func _refresh_all() -> void:
	rations_label.text = "Rations: %d" % GameState.get_resource("rations")
	parts_label.text = "Parts: %d" % GameState.get_resource("parts")
	energy_label.text = "Energy Cells: %d" % GameState.get_resource("energy_cells")

func _on_resource_changed(_id: String, _amount: int) -> void:
	_refresh_all()
