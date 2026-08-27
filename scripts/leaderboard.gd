extends Node
## Autoload singleton. Register this as "Leaderboard" in
## Project Settings > Autoload (path: res://leaderboard.gd)

const SAVE_PATH := "user://leaderboard.json"
const MAX_ENTRIES := 10

## Pass the Dictionary returned by Score.end_run(). Returns the updated,
## sorted, trimmed entry list (so a UI can render it immediately).
func add_entry(player_name: String, result: Dictionary) -> Array:
	var entries := load_entries()
	entries.append({
		"name": player_name if player_name != "" else "Player",
		"score": result.get("score", 0),
		"kills": result.get("kills", 0),
		"max_combo": result.get("max_combo", 0),
		"damage_taken": result.get("damage_taken", 0.0),
		"duration": result.get("duration", 0.0),
		"date": Time.get_datetime_string_from_system(),
	})
	entries.sort_custom(func(a, b): return a["score"] > b["score"])
	entries = entries.slice(0, MAX_ENTRIES)
	save_entries(entries)
	return entries

func load_entries() -> Array:
	if not FileAccess.file_exists(SAVE_PATH):
		return []
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) == TYPE_ARRAY:
		return parsed
	return []

func save_entries(entries: Array) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(entries, "\t"))
	file.close()

## Where a given score would land (1-indexed) without actually saving it.
func get_rank_of(score: int, entries: Array = []) -> int:
	if entries.is_empty():
		entries = load_entries()
	for i in entries.size():
		if score >= entries[i]["score"]:
			return i + 1
	return entries.size() + 1
