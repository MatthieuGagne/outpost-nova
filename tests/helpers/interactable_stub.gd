# tests/helpers/interactable_stub.gd
# A minimal interactable for InteractScan tests. Records that it was called so a test can
# assert the duck-typed contract without a real prop scene.
extends Node3D

var interact_count := 0


func interact() -> void:
	interact_count += 1
