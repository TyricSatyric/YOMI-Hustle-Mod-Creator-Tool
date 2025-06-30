tool
extends Label
export var timer = 5.0
var initial_value
var finished = false
var locked = true
signal timer_finished

func _ready():
	initial_value = timer

func _process(delta):
	if locked: return
	timer -= delta
	if timer <= 0:
		if not finished:
			finished = true
			emit_signal("timer_finished")
		text = ""
	else:
		text = str(int(ceil(timer)))

func reset_timer():
	locked = false
	finished = false
	timer = initial_value
