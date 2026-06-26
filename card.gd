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
	$VBoxContainer/CardImage.texture = load(data["image"])
	$VBoxContainer/NameLabel.text = card_name
	$VBoxContainer/CostLabel.text = "Cost: " + str(cost)
	$VBoxContainer/DescLabel.text = description
	
	
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
