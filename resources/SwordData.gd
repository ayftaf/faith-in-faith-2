extends Resource
class_name SwordData

@export var swordName: String = ""
@export var description: String = ""
@export var artwork: Texture2D = null

# Each sword has exactly 2 spells
@export var spellOneName: String = ""
@export var spellOneDescription: String = ""
@export var spellOneEffectType: String = ""
@export var spellOneEffectValue: int = 0

# Trigger condition: "always", "on_damage_taken", "on_card_played", "on_enemy_turn"
@export var spellOneTrigger: String = "always"

@export var spellTwoName: String = ""
@export var spellTwoDescription: String = ""
@export var spellTwoEffectType: String = ""
@export var spellTwoEffectValue: int = 0
@export var spellTwoTrigger: String = "always"
