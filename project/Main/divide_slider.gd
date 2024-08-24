extends HSlider


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_apply_label(self.value)

func _on_value_changed(v: float) -> void:
	_apply_label(v)

func _apply_label(v: float) -> void:
	label.text = "%d分割" % v


@onready var label: Label = $Label