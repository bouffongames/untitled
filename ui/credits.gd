class_name Credits
extends Control
## This class is responsible for managing the credits screen in the game.
##
## Modified from Maaack's (Marek Belski) menu template.

signal back_button_pressed

@export_file("*.md") var attribution_file_path: String = "res://ATTRIBUTION.md"
@export var h1_font_size: int = 64
@export var h2_font_size: int = 48
@export var h3_font_size: int = 32
@export var h4_font_size: int = 24
@export var current_speed: float = 1.0
@export var scroll_active: bool = true

@export var scroll_container: ScrollContainer
@export var header_space: Control
@export var credits_label: RichTextLabel
@export var footer_space: Control
@export var back_button: Button

var _scroll_accumulator: float

func _ready() -> void:
	scroll_container.scroll_ended.connect(_on_scroll_container_scroll_ended)
	back_button.pressed.connect(_on_back_button_pressed)

	exit()
	_update_text_from_file()
	_set_header_and_footer_size()


func _process(delta: float) -> void:
	var input_axis: float = Input.get_axis("ui_down", "ui_up")
	if input_axis != 0:
		_scroll_container(current_speed * 3 * input_axis * delta)
	else:
		_scroll_container(current_speed * delta)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_text_from_file()
		_set_header_and_footer_size()


func enter() -> void:
	visible = true
	scroll_active = true
	scroll_container.scroll_vertical = 0
	set_process(true)


func exit() -> void:
	visible = false
	await get_tree().process_frame
	set_process(false)
	scroll_active = false
	scroll_container.scroll_vertical = 0


func _on_back_button_pressed() -> void:
	exit()
	back_button_pressed.emit()


func _on_scroll_container_scroll_ended() -> void:
	_end_reached()


func _update_text_from_file() -> void:
	var text: String = _load_file(attribution_file_path, TranslationServer.get_locale())
	if text == "":
		return
	text = text.right(-text.find("\n"))  # Trims first line "ATTRIBUTION"
	text = _regex_replace_urls(text)
	text = _regex_replace_titles(text)
	if is_instance_valid(credits_label):
		credits_label.text = "[center]%s[/center]" % [text]


func _set_header_and_footer_size() -> void:
	if is_instance_valid(header_space):
		header_space.custom_minimum_size.y = size.y
	if is_instance_valid(footer_space):
		footer_space.custom_minimum_size.y = size.y
	if is_instance_valid(credits_label):
		credits_label.custom_minimum_size.x = size.x


func _load_file(file_path: String, locale: String) -> String:
	if not locale.begins_with("en"):
		file_path = file_path.replace(".md", ".%s.md" % locale)
	var file_string: String = FileAccess.get_file_as_string(file_path)
	if file_string != null and not file_string.is_empty():
		return file_string
	if locale.begins_with("en"):
		push_warning("File open error: %s" % FileAccess.get_open_error())
		return ""
	return _load_file(file_path, "en")


func _regex_replace_urls(credits: String) -> String:
	var regex: RegEx = RegEx.new()
	var match_string: String = "\\[([^\\]]*)\\]\\(([^\\)]*)\\)"
	var replace_string: String = "[url=$2]$1[/url]"
	regex.compile(match_string)
	return regex.sub(credits, replace_string, true)


func _regex_replace_titles(credits: String) -> String:
	var iter: int = 0
	var heading_font_sizes: Array[int] = [h1_font_size, h2_font_size, h3_font_size, h4_font_size]
	for heading_font_size: int in heading_font_sizes:
		iter += 1
		var regex: RegEx = RegEx.new()
		var match_string: String = "([^#])#{%d}\\s([^\n]*)" % iter
		var replace_string: String = "$1[font_size=%d]$2[/font_size]" % [heading_font_size]
		regex.compile(match_string)
		credits = regex.sub(credits, replace_string, true)
	return credits


func _check_end_reached(previous_scroll: float) -> void:
	if previous_scroll != scroll_container.scroll_vertical:
		return
	_end_reached()


func _end_reached() -> void:
	if scroll_container.scroll_vertical == 0:
		return
	scroll_active = false
	back_button.pressed.emit()


func _scroll_container(amount: float) -> void:
	if not scroll_active:
		return
	var previous_scroll: float = scroll_container.scroll_vertical
	_scroll_accumulator += amount
	var scroll_amount: int = round(_scroll_accumulator)
	if scroll_amount != 0:
		scroll_container.scroll_vertical += scroll_amount
		_scroll_accumulator -= scroll_amount
		_check_end_reached(previous_scroll)
