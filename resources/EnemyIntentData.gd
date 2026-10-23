extends Resource
class_name EnemyIntentData

enum IntentType {
	ATTACK,        # deal damage to player
	POISON,        # apply poison stacks (damage over time)
	BURN_CARD,     # destroy a random card in player's hand
	SHIELD,        # gain shield points
	HEAL,          # heal self
	BUFF_ATTACK,   # increase own attack damage permanently
	OFFER_CHOICE,  # present player with a decision
	DEBUFF         # reduce player's next card effectiveness
}

@export var intentType: IntentType = IntentType.ATTACK
@export var value: int = 0          # damage / poison stacks / shield amount / heal amount etc.
@export var description: String = "" # shown to player as the intent tooltip

# Probability weight relative to other intents (higher = more likely)
@export var weight: int = 1
