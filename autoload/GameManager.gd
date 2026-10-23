extends Node


# --- Player Health ---
var playerHp: int = 30
var playerMaxHp: int = 30

# --- Card Collection ---
# Each entry: { "cardData": CardData, "token": String or null }
var cardCollection: Array = []

# --- Current Deck (set in deck building, used in combat) ---
# Same structure as cardCollection entries
var currentDeck: Array = []

# --- Sword ---
var currentSword: SwordData = null

# --- poison stacks persistent entre les combats donc il faut une var globale ---
var playerPoisonStacks: int = 0

# --- Combat Setup ---
# Called by the overworld or a trigger before switching to combat scene
var pendingEnemies: Array[EnemyData] = []

# --- Overworld State ---
var playerGridPosition: Vector2i = Vector2i(2, 2)

# IDs of NPCs already spoken to
var talkedToNpcs: Array[String] = []

# IDs of encounters already cleared
var clearedEncounters: Array[String] = []

# IDs of shortcuts already unlocked
var unlockedShortcuts: Array[String] = []

func startCombat(enemies: Array[EnemyData]) -> void:
	pendingEnemies = enemies
	goToScene("res://scenes/combat/Combat.tscn")

func goToScene(path: String) -> void:
	get_tree().change_scene_to_file(path)

func goToCombat() -> void:
	goToScene("res://scenes/combat/Combat.tscn")

func goToDeckBuilding() -> void:
	goToScene("res://scenes/deck_building/DeckBuilding.tscn")

func goToOverworld() -> void:
	goToScene("res://scenes/overworld/Overworld.tscn")

# --- Helpers ---
func healPlayer(amount: int) -> void:
	playerHp = min(playerHp + amount, playerMaxHp)

func damagePlayer(amount: int) -> void:
	playerHp = max(playerHp - amount, 0)

func isPlayerDead() -> bool:
	return playerHp <= 0
