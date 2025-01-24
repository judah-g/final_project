extends CanvasLayer

signal start_game

var timer = 0.0
var lap = 1

func _process(delta):
	timer += delta
	$Timer.text = str(round(timer))
	$Lap.text = str(lap) + " of 3"
	if Input.is_action_pressed("restart"):
		_on_start_button_pressed()

func _on_start_button_pressed():
	$Button.hide()
	$Title.hide()
	start_game.emit()
	timer = 0
	$Timer.visible = true
	$Lap.visible = true
	lap = 1
	$Controls.hide()

func _on_player_race_finish():
	$Title.text = str(round(timer)) + " seconds"
	$Button.show()
	$Title.show()
	$Timer.visible = false
	$Lap.visible = false
	

func _on_player_lap():
	lap += 1
