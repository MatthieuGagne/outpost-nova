# scripts/derelict/room_generator.gd
extends Node

const ROOM_POOL = [
	"res://scenes/derelict/rooms/room_a.tscn",
	"res://scenes/derelict/rooms/room_b.tscn",
]
const EXIT_ROOM = "res://scenes/derelict/rooms/room_exit.tscn"
const ROOMS_PER_RUN = 4

func generate_sequence() -> Array:
	var sequence = []
	for i in range(ROOMS_PER_RUN - 1):
		sequence.append(ROOM_POOL[randi() % ROOM_POOL.size()])
	sequence.append(EXIT_ROOM)
	return sequence
