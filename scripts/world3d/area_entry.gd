class_name AreaEntry
extends RefCounted

## Resolves the Marker3D name a 3D room authors for a given previous area
## (issue #129 R4). The runner finds "EntryFrom<PrevArea>" in PascalCase.

static func marker_name(prev_area_id: String) -> String:
	return "EntryFrom" + snake_to_pascal(prev_area_id)

static func snake_to_pascal(s: String) -> String:
	var out := ""
	for part in s.split("_"):
		if part.is_empty():
			continue
		out += part[0].to_upper() + part.substr(1)
	return out
