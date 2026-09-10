# scripts/poc3d/poc_dialogue_line.gd
class_name PocDialogueLine
extends RefCounted

## Builds the Dictionary that dialogue_box.run_line_async() expects, without YarnSpinner's
## DialogueRunner. PRD 3 (#103) R7.
##
## Why this exists: DialogueRunner is set up in main.gd._setup_dialogue_runner(), which
## this PRD deliberately does not touch, and re-doing that Yarn wiring would prove nothing
## about the 3D move. The question worth answering is whether the dialogue UI LAYERS
## correctly over the low-res SubViewport — a hardcoded line answers that far cheaper.
##
## The shape below is exactly what YarnSpinner.LocalizedLine.from_dictionary() and
## MarkupParseResult.from_dictionary() read (see
## addons/YarnSpinner-Godot/Runtime/Views/GDScriptHelper.gd). Both push_error and return
## null on a missing key, so a drift in that addon fails loudly in this file's tests
## rather than silently on screen.

## The markup attribute name YarnSpinner reserves for the speaker.
const CHARACTER_ATTRIBUTE := "character"

## What separates the speaker from the body in the flattened text. The `character`
## attribute covers the speaker plus this separator, and delete_range() removes exactly
## that span to recover the body.
const SPEAKER_SEPARATOR := ": "

## Line ids are Yarn's localisation handle. Nothing localises a POC line, but the key must
## be present and distinguishable in a log.
const LINE_ID_PREFIX := "line:poc-"


static func build(speaker: String, body: String) -> Dictionary:
	var prefix := speaker + SPEAKER_SEPARATOR
	var full_text := prefix + body
	return {
		"text": {
			"text": full_text,
			"attributes": [{
				"name": CHARACTER_ATTRIBUTE,
				"position": 0,
				"length": prefix.length(),
				"properties": {"name": speaker},
			}],
		},
		"text_id": LINE_ID_PREFIX + speaker.to_lower(),
		"raw_text": full_text,
		"substitutions": [],
		"metadata": [],
	}
