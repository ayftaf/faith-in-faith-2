extends Node

# --- Signals ---
signal handUpdated
signal enemyUpdated(enemyIndex: int)
signal playerStateUpdated
signal combatEnded(playerWon: bool)
signal enemyTurnStarted
signal spellAvailabilityChanged

# --- Inner class: runtime state for one enemy ---
class EnemyState:
	var data: EnemyData
	var currentHp: int
	var currentShield: int
	var statuses: Dictionary
	var isAlive: bool

	func _init(enemyData: EnemyData) -> void:
		data = enemyData
		currentHp = enemyData.maxHp
		currentShield = 0
		statuses = {}
		isAlive = true

# --- Card Piles ---
var drawPile: Array = []
var hand: Array = []
var discardPile: Array = []

# --- Enemies ---
var enemies: Array = []

# --- Player Combat State ---
var playerShield: int = 0
var playerStatuses: Dictionary = {}

# --- Turn Tracking ---
var cardsPlayedCount: int = 0
var cardsDrawnCount: int = 0

# --- Spell Availability ---
var spellOneAvailable: bool = false
var spellTwoAvailable: bool = false

# --- Selected Target ---
var selectedTarget: int = 0

const HAND_SIZE: int = 6

# -------------------------------------------------------
# INIT
# -------------------------------------------------------

func initCombat() -> void:
	drawPile = GameManager.currentDeck.duplicate()
	drawPile.shuffle()
	hand = []
	discardPile = []
	cardsPlayedCount = 0
	cardsDrawnCount = 0
	playerShield = 0
	playerStatuses = {}
	if GameManager.playerPoisonStacks > 0:
		playerStatuses["poison"] = GameManager.playerPoisonStacks

	enemies = []
	for enemyData in GameManager.pendingEnemies:
		enemies.append(EnemyState.new(enemyData))

	_updateSpellAvailability()
	drawCards(HAND_SIZE)

# -------------------------------------------------------
# DRAWING
# -------------------------------------------------------

func drawCards(amount: int) -> void:
	for i in range(amount):
		drawCard()
	emit_signal("handUpdated")

func drawCard() -> void:
	if drawPile.is_empty():
		if discardPile.is_empty():
			emit_signal("combatEnded", false)
			return
		drawPile = discardPile.duplicate()
		drawPile.shuffle()
		discardPile = []

	hand.append(drawPile.pop_back())
	cardsDrawnCount += 1
	_checkSpellTrigger("on_card_drawn")

# -------------------------------------------------------
# PLAYING CARDS
# -------------------------------------------------------

func playCard(handIndex: int) -> void:
	if handIndex < 0 or handIndex >= hand.size():
		return

	var entry = hand[handIndex]
	hand.remove_at(handIndex)
	discardPile.append(entry)

	CardEffects.apply(entry, selectedTarget, self)

	cardsPlayedCount += 1

	if hand.is_empty():
		drawCards(HAND_SIZE)
	else:
		emit_signal("handUpdated")

	_checkEnemyTurnTriggers()
	_checkSpellTrigger("on_card_played")

func _checkEnemyTurnTriggers() -> void:
	var anyActed = false
	for i in range(enemies.size()):
		var enemy: EnemyState = enemies[i]
		if not enemy.isAlive:
			continue
		if enemy.data.cardsPerEnemyTurn > 0:
			if cardsPlayedCount % enemy.data.cardsPerEnemyTurn == 0:
				anyActed = true
				_doSingleEnemyTurn(i)

	if anyActed:
		_checkSpellTrigger("on_enemy_turn")

# -------------------------------------------------------
# ENEMY TURNS
# -------------------------------------------------------

func _doSingleEnemyTurn(enemyIndex: int) -> void:
	emit_signal("enemyTurnStarted")

	var enemy: EnemyState = enemies[enemyIndex]

	# Status ticks on enemy
	for statusType in enemy.statuses.keys():
		match statusType:
			"poison":
				enemy.currentHp = max(0, enemy.currentHp - enemy.statuses[statusType])
		enemy.statuses[statusType] -= 1
		if enemy.statuses[statusType] <= 0:
			enemy.statuses.erase(statusType)

	if enemy.currentHp <= 0:
		enemy.isAlive = false
		emit_signal("enemyUpdated", enemyIndex)
		if _allEnemiesDead():
			emit_signal("combatEnded", true)
		return

	# Skip intent if stunned
	if enemy.statuses.has("stun"):
		emit_signal("enemyUpdated", enemyIndex)
		return

	# Shield regen
	enemy.currentShield += enemy.data.shieldPerTurn

	# Pick and execute intent
	var intent = EnemyIntents.pickIntent(enemy)
	if intent:
		EnemyIntents.applyIntent(intent, enemy, enemyIndex, self)

	emit_signal("enemyUpdated", enemyIndex)

	# Player status ticks
	if playerStatuses.has("poison"):
		GameManager.damagePlayer(playerStatuses["poison"])
		playerStatuses["poison"] -= 1
		if playerStatuses["poison"] <= 0:
			playerStatuses.erase("poison")
		emit_signal("playerStateUpdated")
		if GameManager.isPlayerDead():
			emit_signal("combatEnded", false)

# -------------------------------------------------------
# SWORD SPELLS
# -------------------------------------------------------

func useSpell(spellIndex: int) -> void:
	if GameManager.currentSword == null:
		return

	var sword: SwordData = GameManager.currentSword

	if spellIndex == 0 and spellOneAvailable:
		CardEffects.applySpell(sword.spellOneEffectType, sword.spellOneEffectValue, selectedTarget, self)
		spellOneAvailable = false
		emit_signal("spellAvailabilityChanged")
	elif spellIndex == 1 and spellTwoAvailable:
		CardEffects.applySpell(sword.spellTwoEffectType, sword.spellTwoEffectValue, selectedTarget, self)
		spellTwoAvailable = false
		emit_signal("spellAvailabilityChanged")

func _updateSpellAvailability() -> void:
	if GameManager.currentSword == null:
		spellOneAvailable = false
		spellTwoAvailable = false
		emit_signal("spellAvailabilityChanged")
		return

	var sword: SwordData = GameManager.currentSword
	spellOneAvailable = (sword.spellOneTrigger == "always")
	spellTwoAvailable = (sword.spellTwoTrigger == "always")
	emit_signal("spellAvailabilityChanged")

func _checkSpellTrigger(triggerEvent: String) -> void:
	if GameManager.currentSword == null:
		return

	var sword: SwordData = GameManager.currentSword
	var changed = false

	if not spellOneAvailable and sword.spellOneTrigger == triggerEvent:
		spellOneAvailable = true
		changed = true
	if not spellTwoAvailable and sword.spellTwoTrigger == triggerEvent:
		spellTwoAvailable = true
		changed = true

	if changed:
		emit_signal("spellAvailabilityChanged")

# -------------------------------------------------------
# HELPERS
# -------------------------------------------------------

func _allEnemiesDead() -> bool:
	for enemy in enemies:
		if enemy.isAlive:
			return false
	return true

func setTarget(index: int) -> void:
	if index >= 0 and index < enemies.size():
		selectedTarget = index

func _checkEmptyHand() -> void:
	if hand.is_empty():
		drawCards(HAND_SIZE)
