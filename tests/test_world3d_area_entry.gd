extends GutTest

func test_marker_name_pascal_cases_prev_area():
	assert_eq(AreaEntry.marker_name("cantina"), "EntryFromCantina")
	assert_eq(AreaEntry.marker_name("security_post"), "EntryFromSecurityPost")
	assert_eq(AreaEntry.marker_name("derelict_entrance"), "EntryFromDerelictEntrance")
	assert_eq(AreaEntry.marker_name(""), "EntryFrom")
