tool
extends Label
var timer = 5.0
var finished = false
signal timer_finished

func _process(delta):
	timer -= delta
	if timer <= 0:
		if not finished:
			finished = true
			emit_signal("timer_finished")
		text = ""
	else:
		text = str(int(ceil(timer)))

func reset_timer():
	finished = false
	timer = 5
