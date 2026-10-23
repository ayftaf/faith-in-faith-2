extends Object
class_name EnemyIntents

static func pickIntent(enemy) -> EnemyIntentData:
	if enemy.data.intents.is_empty():
		return null

	var totalWeight = 0
	for intent in enemy.data.intents:
		totalWeight += intent.weight

	var roll = randi() % totalWeight
	var cumulative = 0
	for intent in enemy.data.intents:
		cumulative += intent.weight
		if roll < cumulative:
			return intent

	return enemy.data.intents[0]

static func applyIntent(intent: EnemyIntentData, enemy, enemyIndex: int, cm: Node) -> void:
	match intent.intentType:
		EnemyIntentData.IntentType.ATTACK:
			var damage = intent.value
			if cm.playerShield > 0:
				var absorbed = min(cm.playerShield, damage)
				cm.playerShield -= absorbed
				damage -= absorbed
			GameManager.damagePlayer(damage)
			cm.emit_signal("playerStateUpdated")
			cm._checkSpellTrigger("on_damage_taken")
			if GameManager.isPlayerDead():
				cm.emit_signal("combatEnded", false)

		EnemyIntentData.IntentType.POISON:
			if not cm.playerStatuses.has("poison"):
				cm.playerStatuses["poison"] = 0
			cm.playerStatuses["poison"] += intent.value
			cm.emit_signal("playerStateUpdated")

		EnemyIntentData.IntentType.BURN_CARD:
			if not cm.hand.is_empty():
				cm.hand.remove_at(randi() % cm.hand.size())
				cm.emit_signal("handUpdated")

		EnemyIntentData.IntentType.SHIELD:
			enemy.currentShield += intent.value
			cm.emit_signal("enemyUpdated", enemyIndex)

		EnemyIntentData.IntentType.HEAL:
			enemy.currentHp = min(enemy.currentHp + intent.value, enemy.data.maxHp)
			cm.emit_signal("enemyUpdated", enemyIndex)

		EnemyIntentData.IntentType.BUFF_ATTACK:
			for i in range(enemy.data.intents.size()):
				if enemy.data.intents[i].intentType == EnemyIntentData.IntentType.ATTACK:
					enemy.data.intents[i].value += intent.value

		EnemyIntentData.IntentType.DEBUFF:
			pass

		EnemyIntentData.IntentType.OFFER_CHOICE:
			pass
