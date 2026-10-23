extends Node2D
class_name OverworldNPC

@export var character_name: String = "Voyageur"
@export var dialogue_lines: Array[String] = ["Bonjour, voyageur."]

func _ready() -> void:
	add_to_group("overworld_npc")
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2(0, 8), 17, Color(0.08, 0.10, 0.12, 0.35))
	draw_circle(Vector2.ZERO, 18, Color("#c88964"))
	draw_circle(Vector2(0, -3), 11, Color("#e8c7a0"))
	draw_rect(Rect2(-9, 7, 18, 17), Color("#637a55"), true)
	draw_circle(Vector2(0, -5), 2, Color("#282525"))
	draw_circle(Vector2(6, -5), 2, Color("#282525"))
	draw_arc(Vector2.ZERO, 20, 0, TAU, 32, Color("#282525"), 2)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(-48, -28),
		character_name,
		HORIZONTAL_ALIGNMENT_CENTER,
		96,
		14,
		Color("#fff4d6")
	)
