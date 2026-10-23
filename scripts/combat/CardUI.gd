extends PanelContainer
class_name CardUI

signal cardClicked(index: int)
signal cardHovered(index: int)
signal cardUnhovered

@onready var cardArtwork: TextureRect = $CardVBox/CardArtwork
@onready var cardNameLabel: Label = $CardVBox/CardNameLabel
@onready var cardDescLabel: Label = $CardVBox/CardDescLabel
@onready var tokenLabel: Label = $CardVBox/TokenLabel

var handIndex: int = 0

func setup(entry: Dictionary, index: int) -> void:
	handIndex = index
	var cardData: CardData = entry["cardData"]
	var token: String = entry.get("token", "")

	cardNameLabel.text = cardData.cardName
	cardDescLabel.text = cardData.description

	if cardData.artwork:
		cardArtwork.texture = cardData.artwork

	if token != "" and cardData.canHoldToken:
		tokenLabel.text = "[%s]" % token
		tokenLabel.visible = true
	else:
		tokenLabel.visible = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			emit_signal("cardClicked", handIndex)

func _mouse_enter() -> void:
	emit_signal("cardHovered", handIndex)

func _mouse_exit() -> void:
	emit_signal("cardUnhovered")
