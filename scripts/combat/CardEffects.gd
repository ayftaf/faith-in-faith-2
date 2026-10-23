extends Object
class_name CardEffects

static func apply(entry: Dictionary, targetIndex: int, cm: Node) -> void:
	var cardData: CardData = entry["cardData"]
	var token: String = entry.get("token", "")

	var effectType = cardData.effectType
	var effectValue = cardData.effectValue

	if token != "" and cardData.canHoldToken:
		effectType = cardData.tokenEffectType
		effectValue = cardData.tokenEffectValue

	applyEffect(effectType, effectValue, cardData.element, targetIndex, cm)

static func applySpell(effectType: String, effectValue: int, targetIndex: int, cm: Node) -> void:
	applyEffect(effectType, effectValue, CardData.Element.NONE, targetIndex, cm)

static func applyEffect(effectType: String, effectValue: int, element: CardData.Element, targetIndex: int, cm: Node) -> void:
	match effectType:
		"damage":
			dealDamageToEnemy(targetIndex, effectValue, element, cm)
		"heal":
			GameManager.healPlayer(effectValue)
			cm.emit_signal("playerStateUpdated")
		"shield":
			cm.playerShield += effectValue
			cm.emit_signal("playerStateUpdated")
		"draw":
			cm.drawCards(effectValue)
		"poison", "stun", "burn", "freeze": #tous les effets de statut
			if targetIndex < cm.enemies.size():
				var enemy = cm.enemies[targetIndex]
				if not enemy.statuses.has(effectType):
					enemy.statuses[effectType] = 0
				enemy.statuses[effectType] += effectValue
				cm.emit_signal("enemyUpdated", targetIndex)
		"discard_left":
			if not cm.hand.is_empty():
				cm.discardPile.append(cm.hand[0])
				cm.hand.remove_at(0)
				cm._checkEmptyHand()
				if not cm.hand.is_empty():
					cm.emit_signal("handUpdated")

static func dealDamageToEnemy(targetIndex: int, amount: int, element: CardData.Element, cm: Node) -> void:
	if targetIndex < 0 or targetIndex >= cm.enemies.size():
		return

	var enemy = cm.enemies[targetIndex]
	if not enemy.isAlive:
		return

	# Immunity check
	if element in enemy.data.immunities:
		return

	# Lightning ignores shield
	if element != CardData.Element.LIGHTNING and enemy.currentShield > 0:
		var absorbed = min(enemy.currentShield, amount)
		enemy.currentShield -= absorbed
		amount -= absorbed

	enemy.currentHp = max(0, enemy.currentHp - amount)

	if enemy.currentHp <= 0:
		enemy.isAlive = false

	cm.emit_signal("enemyUpdated", targetIndex)

	if cm._allEnemiesDead():
		cm.emit_signal("combatEnded", true)
