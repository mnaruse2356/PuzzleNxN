extends Line2D

func _ready() -> void:
	var half_length = rect_length * 0.5
	points[0].x = -half_length
	points[0].y = -half_length
	points[1].x = half_length
	points[1].y = -half_length
	points[2].x = half_length
	points[2].y = half_length
	points[3].x = -half_length
	points[3].y = half_length

@export var rect_length: float = 512