extends Node2D

var playing = false

func new_game():
	playing = true
	$player.start_game()
	$player.visible = true


func _on_hud_start_game():
	new_game()
