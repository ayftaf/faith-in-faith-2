extends Resource
class_name CardData
enum Element { NONE, FIRE, LIGHTNING, LIFE, VOID}

@export var cardName: String = ""
@export var description: String = ""
@export var artwork: Texture2D = null
@export var element: Element = Element.NONE

# What this card does: "damage", "heal", "draw", "shield"
@export var effectType: String = ""
@export var effectValue: int = 0

# Token slot: leave empty if this card can't hold a token
@export var canHoldToken: bool = false
@export var tokenDescription: String = ""
@export var tokenEffectType: String = ""
@export var tokenEffectValue: int = 0
