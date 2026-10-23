extends Resource
class_name EnemyData

@export var enemyName: String = ""
@export var artwork: Texture2D = null
@export var maxHp: int = 20
@export var shieldPerTurn: int = 0

# List of elements this enemy takes 0 damage from
@export var immunities: Array[CardData.Element] = []

# How many player cards trigger one enemy turn
@export var cardsPerEnemyTurn: int = 3

# Pool of possible actions — combat manager picks one each turn using weights
@export var intents: Array[EnemyIntentData] = []
