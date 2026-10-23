extends Node2D

@onready var combatManager: Node = $CombatManager
@onready var enemyArea: HBoxContainer = $UI/Root/RightPanel/EnemyArea
@onready var handArea: HBoxContainer = $UI/Root/RightPanel/HandArea
@onready var swordNameLabel: Label = $UI/Root/LeftPanel/LeftVBox/SwordPanel/SwordVBox/SwordNameLabel
@onready var swordDescLabel: Label = $UI/Root/LeftPanel/LeftVBox/SwordPanel/SwordVBox/SwordDescLabel
@onready var cardDetailNameLabel: Label = $UI/Root/LeftPanel/LeftVBox/SwordPanel/SwordVBox/CardDetailNameLabel
@onready var cardDetailDescLabel: Label = $UI/Root/LeftPanel/LeftVBox/SwordPanel/SwordVBox/CardDetailDescLabel
@onready var spellOneButton: Button = $UI/Root/LeftPanel/LeftVBox/SpellsHBox/SpellOneButton
@onready var spellTwoButton: Button = $UI/Root/LeftPanel/LeftVBox/SpellsHBox/SpellTwoButton
@onready var playerHpLabel: Label = $UI/Root/LeftPanel/LeftVBox/PlayerStatsPanel/PlayerVBox/PlayerHpLabel
@onready var playerShieldLabel: Label = $UI/Root/LeftPanel/LeftVBox/PlayerStatsPanel/PlayerVBox/PlayerShieldLabel
@onready var playerStatusLabel: Label = $UI/Root/LeftPanel/LeftVBox/PlayerStatsPanel/PlayerVBox/PlayerStatusLabel

const EnemyUIScene = preload("res://scenes/combat/EnemyUI.tscn")
const CardUIScene = preload("res://scenes/combat/CardUI.tscn")

# -------------------------------------------------------
# READY
# -------------------------------------------------------

func _ready() -> void:
	# --- TEST DATA - remove before shipping ---
	var attackCard = load("res://resources/cards/attack.tres")
	var blockCard = load("res://resources/cards/block.tres")
	GameManager.currentDeck = [
		{"cardData": attackCard, "token": ""},
		{"cardData": attackCard, "token": ""},
		{"cardData": attackCard, "token": ""},
		{"cardData": blockCard, "token": ""},
		{"cardData": blockCard, "token": ""},
		{"cardData": blockCard, "token": ""},
		{"cardData": attackCard, "token": ""},
		{"cardData": blockCard, "token": ""},
	]
	GameManager.currentSword = load("res://resources/swords/test_sword.tres")
	GameManager.pendingEnemies = [load("res://resources/enemies/oure.tres")]
	# --- END TEST DATA ---
	_connectSignals()
	_setupSwordUI()
	combatManager.initCombat()
	_setupEnemies()
	_refreshPlayerStats()
	_refreshTurnCounters()

func _connectSignals() -> void:
	combatManager.handUpdated.connect(_onHandUpdated)
	combatManager.enemyUpdated.connect(_onEnemyUpdated)
	combatManager.playerStateUpdated.connect(_refreshPlayerStats)
	combatManager.combatEnded.connect(_onCombatEnded)
	combatManager.spellAvailabilityChanged.connect(_onSpellAvailabilityChanged)
	spellOneButton.pressed.connect(func(): combatManager.useSpell(0))
	spellTwoButton.pressed.connect(func(): combatManager.useSpell(1))

# -------------------------------------------------------
# SWORD UI
# -------------------------------------------------------

func _setupSwordUI() -> void:
	var sword: SwordData = GameManager.currentSword
	if sword == null:
		swordNameLabel.text = "No Sword"
		swordDescLabel.text = ""
		spellOneButton.text = "—"
		spellTwoButton.text = "—"
		return

	swordNameLabel.text = sword.swordName
	swordDescLabel.text = sword.description
	spellOneButton.text = sword.spellOneName
	spellTwoButton.text = sword.spellTwoName

# -------------------------------------------------------
# ENEMIES
# -------------------------------------------------------

func _setupEnemies() -> void:
	for i in range(combatManager.enemies.size()):
		var enemyUI: EnemyUI = EnemyUIScene.instantiate()
		enemyArea.add_child(enemyUI)
		enemyUI.setup(combatManager.enemies[i], i)
		enemyUI.enemyClicked.connect(_onEnemyClicked)

func _onEnemyUpdated(enemyIndex: int) -> void:
	var enemyUIs = enemyArea.get_children()
	if enemyIndex < enemyUIs.size():
		enemyUIs[enemyIndex].refresh(combatManager.enemies[enemyIndex])

# -------------------------------------------------------
# HAND
# -------------------------------------------------------

func _onHandUpdated() -> void:
	for child in handArea.get_children():
		child.queue_free()

	for i in range(combatManager.hand.size()):
		var cardUI: CardUI = CardUIScene.instantiate()
		handArea.add_child(cardUI)
		cardUI.setup(combatManager.hand[i], i)
		cardUI.cardClicked.connect(_onCardClicked)
		cardUI.cardHovered.connect(_onCardHovered)
		cardUI.cardUnhovered.connect(_onCardUnhovered)

# -------------------------------------------------------
# PLAYER STATS
# -------------------------------------------------------

func _refreshPlayerStats() -> void:
	playerHpLabel.text = "HP: %d / %d" % [GameManager.playerHp, GameManager.playerMaxHp]

	if combatManager.playerShield > 0:
		playerShieldLabel.text = "Shield: %d" % combatManager.playerShield
		playerShieldLabel.visible = true
	else:
		playerShieldLabel.visible = false

	var statusText = ""
	for statusType in combatManager.playerStatuses.keys():
		statusText += "%s: %d  " % [statusType.capitalize(), combatManager.playerStatuses[statusType]]
	playerStatusLabel.text = statusText.strip_edges()
	playerStatusLabel.visible = statusText != ""

# -------------------------------------------------------
# SPELLS
# -------------------------------------------------------

func _onSpellAvailabilityChanged() -> void:
	spellOneButton.disabled = not combatManager.spellOneAvailable
	spellTwoButton.disabled = not combatManager.spellTwoAvailable

# -------------------------------------------------------
# INPUT CALLBACKS
# -------------------------------------------------------

func _onCardClicked(index: int) -> void:
	combatManager.playCard(index)
	_refreshTurnCounters()

func _onCardHovered(index: int) -> void:
	if index < combatManager.hand.size():
		var cardData: CardData = combatManager.hand[index]["cardData"]
		cardDetailNameLabel.text = cardData.cardName
		cardDetailDescLabel.text = cardData.description

func _onCardUnhovered() -> void:
	cardDetailNameLabel.text = ""
	cardDetailDescLabel.text = ""

func _onEnemyClicked(index: int) -> void:
	combatManager.setTarget(index)
	_highlightTarget(index)

func _highlightTarget(index: int) -> void:
	var enemyUIs = enemyArea.get_children()
	for i in range(enemyUIs.size()):
		enemyUIs[i].modulate = Color(1.4, 1.4, 0.6) if i == index else Color(1, 1, 1)

# -------------------------------------------------------
# COMBAT END
# -------------------------------------------------------

func _onCombatEnded(playerWon: bool) -> void:
	GameManager.playerPoisonStacks = combatManager.playerStatuses.get("poison", 0)
	GameManager.goToOverworld()

func _refreshTurnCounters() -> void:
	var enemyUIs = enemyArea.get_children()
	for i in range(combatManager.enemies.size()):
		if i < enemyUIs.size():
			var enemy = combatManager.enemies[i]
			if enemy.isAlive and enemy.data.cardsPerEnemyTurn > 0:
				var count = enemy.data.cardsPerEnemyTurn - (combatManager.cardsPlayedCount % enemy.data.cardsPerEnemyTurn)
				enemyUIs[i].setTurnCounter(count)
