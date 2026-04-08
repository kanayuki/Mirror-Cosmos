## UITheme — builds and applies a space-dark theme to the entire window.
## Registered as the first autoload so every UI scene inherits it automatically.
extends Node

func _ready() -> void:
	get_window().theme = _build()

func _build() -> Theme:
	var t := Theme.new()

	# ── PanelContainer ────────────────────────────────────────────────────────
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.04, 0.05, 0.13, 0.93)
	panel.border_color = Color(0.25, 0.62, 1.0, 0.50)
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(8)
	panel.set_content_margin_all(20)
	t.set_stylebox("panel", "PanelContainer", panel)

	# ── Button ────────────────────────────────────────────────────────────────
	t.set_stylebox("normal",   "Button", _btn(Color(0.07, 0.09, 0.20, 0.85), Color(0.28, 0.62, 1.0, 0.40)))
	t.set_stylebox("hover",    "Button", _btn(Color(0.10, 0.18, 0.38, 0.95), Color(0.42, 0.82, 1.0, 0.90)))
	t.set_stylebox("pressed",  "Button", _btn(Color(0.14, 0.26, 0.50, 1.00), Color(0.50, 0.92, 1.0, 1.00)))
	t.set_stylebox("disabled", "Button", _btn(Color(0.05, 0.06, 0.14, 0.50), Color(0.20, 0.40, 0.60, 0.25)))
	t.set_stylebox("focus",    "Button", _btn(Color(0.10, 0.18, 0.38, 0.95), Color(0.42, 0.82, 1.0, 0.90)))

	t.set_color("font_color",          "Button", Color(0.82, 0.94, 1.0))
	t.set_color("font_hover_color",    "Button", Color(1.0,  1.0,  1.0))
	t.set_color("font_pressed_color",  "Button", Color(0.70, 0.95, 1.0))
	t.set_color("font_disabled_color", "Button", Color(0.40, 0.50, 0.60))

	# ── Label ─────────────────────────────────────────────────────────────────
	t.set_color("font_color", "Label", Color(0.85, 0.95, 1.0))

	# ── ItemList ──────────────────────────────────────────────────────────────
	var list_bg := StyleBoxFlat.new()
	list_bg.bg_color = Color(0.04, 0.05, 0.13, 0.80)
	list_bg.set_corner_radius_all(4)
	t.set_stylebox("panel", "ItemList", list_bg)
	t.set_color("font_color",          "ItemList", Color(0.78, 0.90, 1.0))
	t.set_color("font_selected_color", "ItemList", Color(1.0,  1.0,  1.0))
	var list_sel := StyleBoxFlat.new()
	list_sel.bg_color = Color(0.12, 0.28, 0.55, 0.85)
	list_sel.set_corner_radius_all(4)
	t.set_stylebox("selected",       "ItemList", list_sel)
	t.set_stylebox("selected_focus", "ItemList", list_sel)

	# ── RichTextLabel ─────────────────────────────────────────────────────────
	t.set_color("default_color", "RichTextLabel", Color(0.82, 0.94, 1.0))

	return t

func _btn(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(6)
	s.content_margin_top    = 10
	s.content_margin_bottom = 10
	s.content_margin_left   = 24
	s.content_margin_right  = 24
	return s
