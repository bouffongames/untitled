class_name SpellButton
extends TextureButton

const NORMAL_COLOR: Color = Color.WHITE
const HOVER_COLOR: Color = Color(0.8, 0.8, 0.8)
const PRESSED_COLOR: Color = Color(0.6, 0.6, 0.6)
const DISABLED_COLOR: Color = Color(0.45, 0.45, 0.45)

@export var spell: Spell

@export var click_mask: DPITexture
## Background for the spell
@export var background_texture: Texture2D
@export var background_color: Color = Color(0.55, 0.35, 0.9, 0.85)
## On for triangles pointing down, so the background fills from their flat top toward the tip.
@export var background_fills_downward: bool = false
## Font, size, color and outline of the seconds left shown while the spell cools down.
@export var cooldown_label_settings: LabelSettings

var _locked: bool = false
var _cooldown_left: float = 0.0
var _background: TextureProgressBar
var _background_start: float = 0.0
var _background_span: float = 1.0
var _cooldown_label: Label


func _ready() -> void:
	set_process(false)
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

	process_mode = Node.PROCESS_MODE_PAUSABLE
	if is_instance_valid(background_texture):
		_background = TextureProgressBar.new()
		_background.texture_progress = background_texture
		_background.tint_progress = background_color
		_background.fill_mode = TextureProgressBar.FILL_TOP_TO_BOTTOM if background_fills_downward else TextureProgressBar.FILL_BOTTOM_TO_TOP
		_background.nine_patch_stretch = true
		_background.max_value = 1.0
		_background.step = 0.0
		_background.show_behind_parent = true
		_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_background)
		_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var image: Image = background_texture.get_image()
		var shape: Rect2i = image.get_used_rect()
		var height: float = image.get_height()
		_background_start = (shape.position.y if background_fills_downward else height - shape.end.y) / height
		_background_span = shape.size.y / height
	_cooldown_label = Label.new()
	_cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cooldown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cooldown_label.label_settings = cooldown_label_settings
	add_child(_cooldown_label)
	_cooldown_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_update_cooldown()

	#text = spell.display_name
	#if shortcut != null and not shortcut.get_as_text().is_empty():
		#text += " (%s)" % shortcut.get_as_text()


func _process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	_update_cooldown()


func set_disable(value: bool) -> void:
	_locked = value
	_update_cooldown()


func start_cooldown() -> void:
	_cooldown_left = spell.cooldown
	_update_cooldown()


func is_on_cooldown() -> bool:
	return _cooldown_left > 0.0


func get_cooldown_left() -> float:
	return _cooldown_left


func get_cooldown_progress() -> float:
	if not is_on_cooldown() or spell.cooldown <= 0.0:
		return 1.0
	return 1.0 - _cooldown_left / spell.cooldown


func _update_cooldown() -> void:
	disabled = _locked or is_on_cooldown()
	set_process(is_on_cooldown())
	if _cooldown_label != null:
		_cooldown_label.visible = is_on_cooldown()
		_cooldown_label.text = str(ceili(_cooldown_left))
	if _background != null:
		_background.value = _background_start + _background_span * get_cooldown_progress()
		_background.self_modulate = DISABLED_COLOR if _locked else Color.WHITE
	_update()


func _update() -> void:
	mouse_default_cursor_shape = CURSOR_ARROW if disabled else CURSOR_POINTING_HAND
	if disabled:
		self_modulate = DISABLED_COLOR
	elif is_pressed():
		self_modulate = PRESSED_COLOR
	elif is_hovered():
		self_modulate = HOVER_COLOR
	else:
		self_modulate = NORMAL_COLOR
