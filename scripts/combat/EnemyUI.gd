extends PanelContainer
class_name EnemyUI

signal enemyClicked(index: int)

@onready var enemyNameLabel: Label = $EnemyVBox/EnemyNameLabel
@onready var enemyArtwork: TextureRect = $EnemyVBox/EnemyArtwork
@onready var hpLabel: Label = $EnemyVBox/HpLabel
@onready var shieldLabel: Label = $EnemyVBox/ShieldLabel
@onready var statusLabel: Label = $EnemyVBox/StatusLabel
@onready var intentLabel: Label = $EnemyVBox/IntentLabel
@onready var turnCounterLabel: Label = $EnemyVBox/TurnCounterLabel

var enemyIndex: int = 0

func setup(enemyState, index: int) -> void:
	enemyIndex = index
	enemyNameLabel.text = enemyState.data.enemyName

	if enemyState.data.artwork:
		enemyArtwork.texture = enemyState.data.artwork

	refresh(enemyState)

func refresh(enemyState) -> void:
	hpLabel.text = "HP: %d / %d" % [enemyState.currentHp, enemyState.data.maxHp]

	if enemyState.currentShield > 0:
		shieldLabel.text = "Shield: %d" % enemyState.currentShield
		shieldLabel.visible = true
	else:
		shieldLabel.visible = false

	var statusText = ""
	for statusType in enemyState.statuses.keys():
		statusText += "%s: %d  " % [statusType.capitalize(), enemyState.statuses[statusType]]
	statusLabel.text = statusText.strip_edges()
	statusLabel.visible = statusText != ""

	if not enemyState.isAlive:
		modulate = Color(0.4, 0.4, 0.4)

func setTurnCounter(cardsUntilTurn: int) -> void:
	turnCounterLabel.text = "Acts in: %d" % cardsUntilTurn

func showIntent(intent: EnemyIntentData) -> void:
	if intent:
		intentLabel.text = intent.description
	else:
		intentLabel.text = ""

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			emit_signal("enemyClicked", enemyIndex)
