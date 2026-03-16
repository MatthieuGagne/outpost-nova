# tests/test_dialogue_manager.gd
extends GutTest

# Minimal test tree
const TEST_TREE = {
	"start": {
		"speaker": "Maris",
		"text": "Hey, you must be new.",
		"choices": [
			{ "text": "Just arrived.", "register": "detached", "next": "end" },
			{ "text": "Yeah, glad to be here.", "register": "hopeful", "next": "end" },
		]
	},
	"end": {
		"speaker": "Maris",
		"text": "Well, welcome.",
		"choices": []
	}
}

const BEAT_TREE = {
	"start": {
		"speaker": "Maris",
		"text": "I need to tell you something.",
		"beat": "maris_confided",
		"choices": [
			{ "text": "I'm listening.", "register": "warm", "next": "end" }
		]
	},
	"end": {
		"speaker": "Maris",
		"text": "Thanks.",
		"choices": []
	}
}

func before_each():
	GameState.reset()
	DayManager.reset()
	DialogueManager.reset()

func test_start_conversation_sets_current_node():
	DialogueManager.start_conversation(TEST_TREE)
	assert_eq(DialogueManager.get_current_node()["speaker"], "Maris")

func test_make_choice_advances_node():
	DialogueManager.start_conversation(TEST_TREE)
	DialogueManager.make_choice(0)
	assert_eq(DialogueManager.get_current_node()["text"], "Well, welcome.")

func test_conversation_ends_on_empty_choices():
	DialogueManager.start_conversation(TEST_TREE)
	DialogueManager.make_choice(0)
	assert_true(DialogueManager.is_conversation_over())

func test_inner_voice_flagged_for_matching_background():
	GameState.set_player_identity("Test", "medic", 0)
	DialogueManager.start_conversation(TEST_TREE)
	var flags = DialogueManager.get_inner_voice_flags()
	# hopeful maps to medic inner voice
	assert_true(flags.has(1))  # index 1 is "hopeful"

func test_beat_completion_fires_on_beat_node():
	DayManager._override_beats_for_test([
		{ "id": "maris_confided", "required": true, "npc": "maris", "flag_to_set": "maris_confided" }
	])
	watch_signals(DialogueManager)
	DialogueManager.start_conversation(BEAT_TREE)
	DialogueManager.make_choice(0)
	assert_signal_emitted(DialogueManager, "story_beat_triggered")

func test_register_history_recorded():
	DialogueManager.start_conversation(TEST_TREE)
	DialogueManager.make_choice(1)  # hopeful
	assert_true(DialogueManager.register_history.has("hopeful"))
