extends Node2D

const MOVE_DURATION: float = 0.12

@onready var map: TileMapLayer = $Map
@onready var player: Node2D = $Map/Player
@onready var dialogue_overlay: ColorRect = $DialogueLayer/Overlay
@onready var dialogue_name: Label = $DialogueLayer/Overlay/CenterContainer/DialoguePanel/Content/NpcName
@onready var dialogue_text: Label = $DialogueLayer/Overlay/CenterContainer/DialoguePanel/Content/DialogueText
@onready var dialogue_button: Button = $DialogueLayer/Overlay/CenterContainer/DialoguePanel/Content/Buttons/ContinueButton

var npc_at_cell: Dictionary = {}
var movement_path: Array[Vector2i] = []
var is_moving: bool = false
var active_npc: OverworldNPC
var dialogue_index: int = 0

func _ready() -> void:
	dialogue_button.pressed.connect(_advance_dialogue)
	_refresh_npcs()
	var start_cell: Vector2i = GameManager.playerGridPosition
	if not _is_walkable(start_cell):
		start_cell = _find_first_walkable_cell()
		GameManager.playerGridPosition = start_cell
	player.position = _cell_center(start_cell)

func _unhandled_input(event: InputEvent) -> void:
	if dialogue_overlay.visible:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			_close_dialogue()
			get_viewport().set_input_as_handled()
		return
	if is_moving:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var direction := _direction_for_key(event.keycode)
		if direction != Vector2i.ZERO:
			_try_move(direction)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_E:
			_interact_with_nearby_npc()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cell := map.local_to_map(map.to_local(get_global_mouse_position()))
		if npc_at_cell.has(cell):
			_open_dialogue(npc_at_cell[cell])
		elif _is_inside_map(cell):
			_move_to_cell(cell)
		get_viewport().set_input_as_handled()

func _refresh_npcs() -> void:
	npc_at_cell.clear()
	for npc in get_tree().get_nodes_in_group("overworld_npc"):
		if not is_instance_valid(npc) or not is_ancestor_of(npc):
			continue
		var npc_node := npc as OverworldNPC
		var cell := map.local_to_map(map.to_local(npc_node.global_position))
		npc_at_cell[cell] = npc_node

func _direction_for_key(keycode: int) -> Vector2i:
	match keycode:
		KEY_W, KEY_Z, KEY_UP:
			return Vector2i.UP
		KEY_A, KEY_Q, KEY_LEFT:
			return Vector2i.LEFT
		KEY_S, KEY_DOWN:
			return Vector2i.DOWN
		KEY_D, KEY_RIGHT:
			return Vector2i.RIGHT
	return Vector2i.ZERO

func _try_move(direction: Vector2i) -> void:
	var next_cell := GameManager.playerGridPosition + direction
	if npc_at_cell.has(next_cell):
		_open_dialogue(npc_at_cell[next_cell])
	elif _is_walkable(next_cell):
		_move_to_cell(next_cell)

func _move_to_cell(target: Vector2i) -> void:
	var path := _find_path(GameManager.playerGridPosition, target)
	if path.is_empty():
		return
	movement_path = path
	_move_next_step()

func _move_next_step() -> void:
	if movement_path.is_empty():
		is_moving = false
		return
	is_moving = true
	var next_cell: Vector2i = movement_path.pop_front()
	var tween := create_tween()
	tween.tween_property(player, "global_position", _cell_center(next_cell), MOVE_DURATION)
	tween.finished.connect(func() -> void:
		GameManager.playerGridPosition = next_cell
		_move_next_step()
	)

func _find_path(start: Vector2i, target: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	if not _is_walkable(target) or target == start:
		return path

	var frontier: Array[Vector2i] = [start]
	var came_from: Dictionary = {start: start}
	var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		if current == target:
			break
		for direction in directions:
			var next_cell: Vector2i = current + direction
			if _is_walkable(next_cell) and not came_from.has(next_cell):
				frontier.append(next_cell)
				came_from[next_cell] = current

	if not came_from.has(target):
		return path
	var current_cell: Vector2i = target
	while current_cell != start:
		path.push_front(current_cell)
		current_cell = came_from[current_cell]
	return path

func _interact_with_nearby_npc() -> void:
	for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
		var cell: Vector2i = GameManager.playerGridPosition + direction
		if npc_at_cell.has(cell):
			_open_dialogue(npc_at_cell[cell])
			return

func _open_dialogue(npc: OverworldNPC) -> void:
	active_npc = npc
	dialogue_index = 0
	dialogue_name.text = npc.character_name
	_update_dialogue_text()
	dialogue_overlay.visible = true
	dialogue_button.grab_focus()

func _advance_dialogue() -> void:
	if active_npc.dialogue_lines.is_empty():
		_close_dialogue()
	elif dialogue_index < active_npc.dialogue_lines.size() - 1:
		dialogue_index += 1
		_update_dialogue_text()
	else:
		_close_dialogue()

func _update_dialogue_text() -> void:
	var lines: Array[String] = active_npc.dialogue_lines
	if lines.is_empty():
		dialogue_text.text = ""
		dialogue_button.text = "Terminer"
		return
	dialogue_text.text = lines[dialogue_index]
	dialogue_button.text = "Continuer" if dialogue_index < lines.size() - 1 else "Terminer"

func _close_dialogue() -> void:
	dialogue_overlay.visible = false
	active_npc = null

func _is_inside_map(cell: Vector2i) -> bool:
	return map.get_used_rect().has_point(cell)

func _is_walkable(cell: Vector2i) -> bool:
	if not _is_inside_map(cell) or npc_at_cell.has(cell):
		return false
	var tile_data := map.get_cell_tile_data(cell)
	return tile_data != null and tile_data.get_custom_data("walkable") == true

func _cell_center(cell: Vector2i) -> Vector2:
	return map.to_global(map.map_to_local(cell))

func _find_first_walkable_cell() -> Vector2i:
	for cell in map.get_used_cells():
		if _is_walkable(cell):
			return cell
	return Vector2i.ZERO
