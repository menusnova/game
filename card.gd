extends Panel


var card_name = ""
var cost = 1
var description = ""

func _ready():

	mouse_entered.connect(_on_mouse_entered)

	mouse_exited.connect(_on_mouse_exited)
func setup(data):

	card_name = data["name"]
	cost = data["cost"]
	description = data["description"]
	var img_node = get_node_or_null("VBoxContainer/CardImage")
	if img_node and data.has("image") and data["image"] != "":
		var tex = ResourceLoader.load(data["image"], "Texture2D")
		if tex:
			img_node.texture = tex
	var name_node = get_node_or_null("VBoxContainer/NameLabel")
	var cost_node = get_node_or_null("VBoxContainer/CostLabel")
	var desc_node = get_node_or_null("VBoxContainer/DescLabel")
	if name_node: name_node.text = card_name
	if cost_node: cost_node.text = "Cost: " + str(cost)
	if desc_node: desc_node.text = description
	
	
signal card_clicked(card_name)

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			card_clicked.emit(card_name)


func _on_mouse_entered():

	var tween = create_tween()

	tween.tween_property(
		self,
		"scale",
		Vector2(1.1,1.1),
		0.1
	)
func _on_mouse_exited():

	var tween = create_tween()

	tween.tween_property(
		self,
		"scale",
		Vector2(1,1),
		0.1
	)
