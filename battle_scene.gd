extends Control




var current_stage = 1
var enemy_data = {}
var card_scene = preload("res://card.tscn")
var card_database = {

	"Hydrogen":{
	"name":"Hydrogen",
	"cost":1,
	"description":"Basic Element",
	"image":"res://cards/Hydrogen.png"
},

"Oxygen":{
	"name":"Oxygen",
	"cost":1,
	"description":"Basic Element",
	"image":"res://cards/Oxygen.png"
},

	"Iron":{
		"name":"Iron",
		"cost":1,
		"description":"Basic Element",
		"image":"res://cards/Iron.png"
	},

	"Sodium":{
		"name":"Sodium",
		"cost":1,
		"description":"Basic Element",
		"image":"res://cards/Sodium.png"
	},

	"Chlorine":{
		"name":"Chlorine",
		"cost":1,
		"description":"Basic Element",
		"image":"res://cards/Chlorine.png"
	},
	"Water":{
	"name":"Water",
	"cost":2,
	"description":"Heal 20 HP",
	"image":"res://cards/Water.png"
	},

	"Salt":{
		"name":"Salt",
		"cost":2,
		"description":"Gain Shield",
		"image":"res://cards/Salt.png"
	},

	"Rust":{
		"name":"Rust",
		"cost":2,
		"description":"Poison Enemy",
		"image":"res://cards/Rust.png"
	}
}
var deck = [
	"Hydrogen",
	"Hydrogen",
	"Hydrogen",
	"Oxygen",
	"Oxygen",
	"Oxygen",
	"Iron",
	"Iron",
	"Sodium",
	"Chlorine"
]

var hand = []
var discard = []

var recipes = {
	"Chlorine+Sodium":"Salt",
	"Hydrogen+Oxygen":"Water",
	"Iron+Oxygen":"Rust"
}
var first_element = ""
var second_element = ""
var crafted_elements = []
var skill_cooldown = 0
var player_turn = true
var main_action_used = false
var is_defending = false
var player_hp = 0
var enemy_hp = 100
var player_shield = 0

var enemy_poison = 0
var enemy_burn = 0
var player_weak = 0
var enemy_weak = 0
var player_vulnerable = 0
var enemy_vulnerable = 0


var max_energy = 5
var current_energy = 5
var max_hand_size = 5
var character_data = {
	"name":"Alchemist",
	"max_hp":100,

	"skill_name":"Power Strike",
	"skill_damage":40,

	"ultimate_name":"Element Burst",
	"ultimate_damage":60,

	"passive":"Reaction Master"
}
var ultimate_gauge = 0
var max_ultimate_gauge = 100


func _ready():

	player_hp = character_data["max_hp"]

	create_enemy()

	draw_until_full()

	update_ui()
func reshuffle_deck():

	if discard.size() == 0:
		return

	deck = discard.duplicate()

	discard.clear()

	deck.shuffle()


	$MessageLabel.text = "Deck Reshuffled!"



	
	
func draw_until_full():

	while hand.size() < max_hand_size:
		draw_card()
func draw_card():
	
	if deck.size() == 0:

		reshuffle_deck()

		if deck.size() == 0:
			return

	var random_index = randi() % deck.size()

	var card = deck[random_index]

	deck.remove_at(random_index)

	hand.append(card)

	update_hand()
	
	
func update_hand():

	for child in $HandContainer.get_children():
		child.queue_free()

	for card in hand:

		var card_ui = card_scene.instantiate()

		card_ui.setup(card_database[card])

		card_ui.card_clicked.connect(
			func(card_name):

			if card_name == "Water":
				use_compound(card_name)

			elif card_name == "Salt":
				use_compound(card_name)

			elif card_name == "Rust":
				use_compound(card_name)

			else:
				select_element(card_name)
	)

		$HandContainer.add_child(card_ui)

		$DeckLabel.text = "Deck: " + str(deck.size())
		$DiscardLabel.text = "Discard: " + str(discard.size())
		
		
func use_compound(card_name):

	if current_energy < 1:
		$MessageLabel.text = "Not enough Energy!"
		return

	current_energy -= 1

	if card_name == "Water":
		player_hp += 20
		if player_hp > 100:
			player_hp = 100
		$MessageLabel.text = "Water Heal +20"

	elif card_name == "Salt":
		player_shield += 20
		$MessageLabel.text = "Salt Shield +20"

	elif card_name == "Rust":
		enemy_hp -= 10
		enemy_poison += 5
		$MessageLabel.text = "Rust Corrosion!"

	remove_card_from_hand(card_name)
	check_battle()
	update_ui()
	update_hand()



func update_ui():
	
	
	$StageLabel.text = "Stage " + str(current_stage)
	$UltimateLabel.text = "Ultimate: " + str(ultimate_gauge) + "/" + str(max_ultimate_gauge)
	if ultimate_gauge >= max_ultimate_gauge:
		$UltimateButton.disabled = false
	else:
		$UltimateButton.disabled = true
	$CharacterNameLabel.text = character_data["name"]
	$PassiveLabel.text = "Passive: " + character_data["passive"]
	$EnergyLabel.text = "Energy: " + str(current_energy) + "/" + str(max_energy)
	$PlayerHP.text = "Player HP: " + str(player_hp)
	$EnemyHP.text = "Enemy HP: " + str(enemy_hp)
	$PlayerHPBar.value = player_hp
	$EnemyHPBar.value = enemy_hp

	if player_turn:
		$TurnLabel.text = "Your Turn"
	else:
		$TurnLabel.text = "Enemy Turn"
		
	$PlayerStatusLabel.text = "Shield: " + str(player_shield)

	$EnemyStatusLabel.text = \
	"Poison:" + str(enemy_poison) + \
	" Burn:" + str(enemy_burn) + \
	" Weak:" + str(enemy_weak)


func remove_card_from_hand(card_name):

	hand.erase(card_name)

	discard.append(card_name)
func check_recipe():

	var elements = [first_element, second_element]
	elements.sort()

	var recipe_key = elements[0] + "+" + elements[1]

	if recipes.has(recipe_key):

		var result = recipes[recipe_key]

		if character_data["passive"] == "Reaction Master":

			ultimate_gauge += 10

			if ultimate_gauge > max_ultimate_gauge:
				ultimate_gauge = max_ultimate_gauge

		crafted_elements.append(result)

		remove_card_from_hand(first_element)
		remove_card_from_hand(second_element)

		hand.append(result)

		update_hand()
		update_ui()

		$MessageLabel.text = "Created " + result + "!"

	else:

		$MessageLabel.text = "No Reaction"

	first_element = ""
	second_element = ""

func check_battle():
	if enemy_hp <= 0:
		$MessageLabel.text = "Enemy Defeated!"
		await get_tree().create_timer(1.0).timeout
		next_stage()
		return

	if player_hp <= 0:
		$MessageLabel.text = "Defeat!"
		$AttackButton.disabled = true
		
		
func _on_attack_button_pressed():
	if !player_turn:
		return
	if main_action_used:
		$MessageLabel.text = "Action already used!"
		return

	main_action_used = true

	var original_x = $EnemySprite.position.x

	var tween = create_tween()

	tween.tween_property(
		$EnemySprite,
		"position:x",
		original_x + 30,
		0.08
	)

	await tween.finished

	var tween2 = create_tween()

	tween2.tween_property(
		$EnemySprite,
		"position:x",
		original_x,
		0.08
	)
	var damage = 20

	if player_weak > 0:
		damage -= 5

	if enemy_vulnerable > 0:
		damage += 5
	
	enemy_hp -= damage
	ultimate_gauge += 15
	if ultimate_gauge > max_ultimate_gauge:
		ultimate_gauge = max_ultimate_gauge
	
	
	check_battle()

	update_ui()

	

func enemy_turn():

	var damage = enemy_data["attack"]

	if is_defending:

		damage = 7

		ultimate_gauge += 20

		if ultimate_gauge > max_ultimate_gauge:
			ultimate_gauge = max_ultimate_gauge

	is_defending = false


	if player_shield > 0:

		var blocked = min(player_shield, damage)

		player_shield -= blocked

		damage -= blocked


	player_hp -= damage

	ultimate_gauge += 10
	if ultimate_gauge > max_ultimate_gauge:
		ultimate_gauge = max_ultimate_gauge

	$PlayerSprite.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout
	$PlayerSprite.modulate = Color(1, 1, 1)

	if skill_cooldown > 0:
		skill_cooldown -= 1

	if enemy_poison > 0:
		enemy_hp -= enemy_poison
		$MessageLabel.text = "Poison deals " + str(enemy_poison)

	check_battle()

	player_turn = true
	if enemy_weak > 0:
		enemy_weak -= 1

	if enemy_vulnerable > 0:
		enemy_vulnerable -= 1
	main_action_used = false

	current_energy = max_energy

	draw_until_full()

	update_ui()
 
func _on_defend_button_pressed():

	if !player_turn:
		return
	if main_action_used:
		$MessageLabel.text = "Action already used!"
		return
	main_action_used = true
	is_defending = true
	
	$MessageLabel.text = "Defending!"


func _on_skill_button_pressed():
	
	if !player_turn:
		return
	if main_action_used:
		$MessageLabel.text = "Action already used!"
		return
	
	if skill_cooldown > 0:
		$MessageLabel.text = "Skill Cooldown!"
		return

	var damage = character_data["skill_damage"]

	if player_weak > 0:
		damage -= 10

	enemy_hp -= damage

	ultimate_gauge += 20

	if ultimate_gauge > max_ultimate_gauge:
		ultimate_gauge = max_ultimate_gauge
	main_action_used = true
	skill_cooldown = 2

	$MessageLabel.text = character_data["skill_name"] + "!"

	check_battle()

	update_ui()

	
	
func select_element(element_name):

	if first_element == "":
		first_element = element_name
		$MessageLabel.text = "First: " + element_name

	else:
		second_element = element_name
		check_recipe()


func _on_end_turn_button_pressed():

	if !player_turn:
		return

	player_turn = false

	update_ui()

	await get_tree().create_timer(0.5).timeout

	enemy_turn()


func _on_ultimate_button_pressed():

	if !player_turn:
		return

	if main_action_used:
		$MessageLabel.text = "Main Action Already Used!"
		return

	if ultimate_gauge < max_ultimate_gauge:
		$MessageLabel.text = "Ultimate Not Ready!"
		return

	main_action_used = true

	ultimate_gauge = 0

	enemy_hp -= character_data["ultimate_damage"]

	$MessageLabel.text = character_data["ultimate_name"] + "!"

	check_battle()

	update_ui()
func create_enemy():

	if current_stage % 5 == 0:

		enemy_data = {
			"name":"Boss",
			"hp":300,
			"attack":25,
			"type":"boss"
		}

	else:

		var enemies = [
			{
				"name":"Slime",
				"hp":100,
				"attack":10,
				"type":"poison"
			},

			{
				"name":"Goblin",
				"hp":80,
				"attack":20,
				"type":"attack"
			},

			{
				"name":"Knight",
				"hp":150,
				"attack":12,
				"type":"tank"
			}
		]

		enemy_data = enemies.pick_random()

	enemy_hp = enemy_data["hp"]

	$EnemyNameLabel.text = enemy_data["name"]
func next_stage():

	current_stage += 1

	create_enemy()

	player_turn = true

	main_action_used = false

	current_energy = max_energy

	draw_until_full()

	update_ui()

	$MessageLabel.text = "Stage " + str(current_stage)
