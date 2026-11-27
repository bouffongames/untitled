class_name SpellButton
extends TextureButton

const NORMAL_COLOR: Color = Color.WHITE
const HOVER_COLOR: Color = Color(0.8, 0.8, 0.8)
const PRESSED_COLOR: Color = Color(0.6, 0.6, 0.6)
const DISABLED_COLOR: Color = Color(0.45, 0.45, 0.45)

@export var spell: Spell

@export var click_mask: DPITexture


func _ready() -> void:
	mouse_entered.connect(_update)
	mouse_exited.connect(_update)
	button_down.connect(_update)
	button_up.connect(_update)
	_update()

	# https://forum.godotengine.org/t/emit-on-mouse-enter-only-when-its-over-non-empty-pixels-in-control/78271/6
	if is_instance_valid(click_mask):
		var image: Image = click_mask.get_image()
		var bitmap: BitMap = BitMap.new()
		bitmap.create_from_image_alpha(image)
		texture_click_mask = bitmap

	visible = spell != null
	if spell == null:
		return

	#text = spell.display_name
	#if shortcut != null and not shortcut.get_as_text().is_empty():
		#text += " (%s)" % shortcut.get_as_text()


func set_disable(value: bool) -> void:
	disabled = value
	_update()


func _update() -> void:
	mouse_default_cursor_shape = CURSOR_ARROW if disabled else CURSOR_POINTING_HAND
	if disabled:
		modulate = DISABLED_COLOR
	elif is_pressed():
		modulate = PRESSED_COLOR
	elif is_hovered():
		modulate = HOVER_COLOR
	else:
		modulate = NORMAL_COLOR
