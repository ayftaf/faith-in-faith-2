extends Node2D

func _draw() -> void:
	draw_circle(Vector2(0, 8), 17, Color(0.08, 0.10, 0.12, 0.35))
	draw_circle(Vector2.ZERO, 18, Color("#e4c36a"))
	draw_circle(Vector2(0, -3), 11, Color("#f0d8a4"))
	draw_rect(Rect2(-8, 7, 16, 16), Color("#436c9e"), true)
	draw_circle(Vector2(0, -5), 2, Color("#282525"))
	draw_circle(Vector2(6, -5), 2, Color("#282525"))
	draw_arc(Vector2.ZERO, 20, 0, TAU, 32, Color("#282525"), 2)
