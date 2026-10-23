class_name TribuneCard
extends Button

signal hovered(card: Dictionary)
var data: Dictionary
var base_position: Vector2
var base_rotation := 0.0
var base_z := 0
var interactive := true
var selected := false
var raised := false
var lift: Tween
var pointer_position := Vector2(-10000,-10000)
const CREAM := Color("f1e4c8")

func setup(info: Dictionary, card_size := Vector2(200,300)) -> void:
	data = info
	size = card_size
	custom_minimum_size = card_size
	pivot_offset = card_size/2
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_mode = Control.FOCUS_NONE
	var k := card_size/Vector2(200,300)
	var skin := "attack" if data.kind == "Attaque" else "skill"
	if data.kind == "Pouvoir": skin = "power"
	if data.kind == "Statut": skin = "status"
	if data.rarity == "Rare": skin = "rare"
	for style_name in ["normal","hover","pressed","focus","disabled"]:
		var s := StyleBoxFlat.new()
		s.bg_color = Color.TRANSPARENT
		s.set_corner_radius_all(12)
		s.shadow_size = 13 if style_name == "hover" else 6
		s.shadow_color = Color(0.25,0.95,0.92,0.55) if style_name == "hover" else Color(0,0,0,0.65)
		add_theme_stylebox_override(style_name,s)
	var tex := AtlasTexture.new()
	tex.atlas = load("res://assets/cards-a.png" if data.art < 10 else "res://assets/cards-b.png")
	var idx: int = data.art % 10
	tex.region = Rect2(48+(idx%5)*329,100+int(idx/5)*454,266,156)
	texture(tex,Vector2(16,44)*k,Vector2(168,109)*k)
	texture(load("res://assets/ui/card-%s.svg" % skin),Vector2.ZERO,card_size)
	label(data.name,Vector2(42,15)*k,Vector2(146,27)*k,roundi(14*k.x),CREAM)
	var cost := label(str(data.cost) if data.cost >= 0 else "–",Vector2(5,7)*k,Vector2(36,36)*k,roundi(27*k.x),Color("fff6cf"))
	cost.add_theme_color_override("font_outline_color",Color("572421"))
	cost.add_theme_constant_override("outline_size",4)
	label(data.kind,Vector2(48,150)*k,Vector2(104,23)*k,roundi(11*k.x),CREAM)
	label(data.description,Vector2(18,176)*k,Vector2(164,93)*k,roundi(14*k.x),CREAM)
	mouse_entered.connect(_enter)
	mouse_exited.connect(_leave)

func texture(tex: Texture2D,pos: Vector2,bounds: Vector2) -> void:
	var art := TextureRect.new()
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.texture = tex
	art.position = pos
	art.size = bounds
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	art.set_deferred("size",bounds)

func label(content: String,pos: Vector2,bounds: Vector2,font_size: int,color: Color) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.text = content
	l.position = pos
	l.size = bounds
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size",font_size)
	l.add_theme_color_override("font_color",color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	l.set_deferred("size",bounds)
	return l

func _process(_delta: float) -> void:
	if raised and interactive and not selected:
		var p := pointer_position
		# Keep the original slot active while its enlarged card rises away from it.
		if not Rect2(base_position-Vector2(18,12),size+Vector2(36,24)).has_point(p) and not Rect2(Vector2.ZERO,size).has_point(get_global_transform().affine_inverse()*p):
			raised = false
			settle()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion: pointer_position = event.position

func _enter() -> void:
	hovered.emit(data)
	if not interactive: return
	raised = true
	if lift: lift.kill()
	z_index = 50
	lift = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	lift.tween_property(self,"position",base_position-Vector2(0,115),0.16)
	lift.tween_property(self,"scale",Vector2.ONE*1.16,0.16)
	lift.tween_property(self,"rotation",0.0,0.16)

func _leave() -> void:
	if not interactive or raised: return
	settle()

func settle() -> void:
	if lift: lift.kill()
	z_index = 45 if selected else base_z
	lift = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	lift.tween_property(self,"position",base_position-Vector2(0,90 if selected else 0),0.18)
	lift.tween_property(self,"scale",Vector2.ONE*(1.1 if selected else 1.0),0.18)
	lift.tween_property(self,"rotation",0.0 if selected else base_rotation,0.18)

func select(value: bool) -> void:
	selected = value
	raised = false
	self_modulate = Color("fff0b6") if value else Color.WHITE
	settle()
