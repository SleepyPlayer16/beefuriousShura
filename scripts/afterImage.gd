extends Sprite2D

var emotion = 0
var colors = [Color("a8ed2f"), Color("ff026a"), Color("2e55d6"), Color("f79417")]

func _process(delta):
	modulate.a -= delta*2
	if modulate.a <= 0:
		queue_free()
