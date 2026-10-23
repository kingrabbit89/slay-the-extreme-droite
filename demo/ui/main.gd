extends Control

const CardView = preload("res://ui/card_view.gd")
const Atmosphere = preload("res://ui/atmosphere.gd")
const Audio = preload("res://ui/audio.gd")
const CombatFx = preload("res://ui/combat_fx.gd")
const GOLD := Color("cfad70")
const CREAM := Color("f2e5cc")
const MUTED := Color("b0b6b3")
const GREEN := Color("73c7aa")
const RED := Color("e17b69")
var core: RefCounted
var state: Dictionary
var page: Control
var overlay: Control
var fx: Control
var atmosphere: Control
var sound: Node
var actors: Array[TextureRect] = []
var hand_views: Array = []
var selected := -1
var busy := false
var in_menu := true
var serif := SystemFont.new()
var sans := SystemFont.new()
var toast_label: Label
var mute_button: Button
var help_label: Label
var saved_code := ""
var reduced_motion := false
var actor_texture: Texture2D
var checkpoint_path := "user://checkpoint.cfg"
var journal: Array[String] = []
var vfx: Control
var hand_origins: Dictionary = {}
var bar_views: Array = []
var shown_stats: Array = []
var animate_hand := false
var draw_all := false
var shake: Tween
var energy_label: Label
var deal_finish := 0.0

func _ready() -> void:
	checkpoint_path = ProjectSettings.globalize_path("res://../saves/checkpoint.cfg") if OS.has_feature("editor") else OS.get_executable_path().get_base_dir().path_join("saves/checkpoint.cfg")
	if "--smoke" in OS.get_cmdline_user_args():
		checkpoint_path = ProjectSettings.globalize_path("res://../build/qa/smoke.cfg") if OS.has_feature("editor") else OS.get_executable_path().get_base_dir().path_join("../qa-export/smoke.cfg")
	serif.font_names = PackedStringArray(["Georgia"])
	sans.font_names = PackedStringArray(["Bahnschrift", "Segoe UI"])
	var ui_theme := Theme.new()
	ui_theme.default_font = sans
	ui_theme.default_font_size = 20
	theme = ui_theme
	core = ClassDB.instantiate("TribuneCore")
	actor_texture = load("res://assets/actors.png")
	var backdrop := TextureRect.new()
	backdrop.texture = load("res://assets/grand-debat.png")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.size = Vector2(1600,900)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	gradient(self,Vector2.ZERO,Vector2(1600,900),Color(0.02,0.04,0.07,0.3),Color(0.015,0.025,0.035,0.94))
	atmosphere = Control.new()
	atmosphere.set_script(Atmosphere)
	add_child(atmosphere)
	page = Control.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(page)
	fx = Control.new()
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.z_index = 90
	add_child(fx)
	vfx = Control.new()
	vfx.set_script(CombatFx)
	vfx.z_index = 80
	add_child(vfx)
	overlay = Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 100
	add_child(overlay)
	sound = Node.new()
	sound.set_script(Audio)
	add_child(sound)
	var cfg := ConfigFile.new()
	if cfg.load(checkpoint_path) == OK:
		saved_code = cfg.get_value("run","code","")
		reduced_motion = cfg.get_value("settings","reduced_motion",false)
		if cfg.get_value("settings","muted",false): sound.toggle()
		sound.set_music(cfg.get_value("settings","music",0.45))
		sound.set_effects(cfg.get_value("settings","effects",0.75))
	atmosphere.reduced_motion = reduced_motion
	vfx.reduced_motion = reduced_motion
	show_menu()
	if "--smoke" in OS.get_cmdline_user_args(): smoke_test.call_deferred()
	if "--showcase" in OS.get_cmdline_user_args(): showcase.call_deferred()

func clear_page() -> void:
	for child in page.get_children(): child.queue_free()
	for child in overlay.get_children(): child.queue_free()
	actors.clear()
	hand_views.clear()
	bar_views.clear()
	shown_stats.clear()
	selected = -1
	help_label = null

func panel(parent: Node, pos: Vector2, bounds: Vector2, color := Color("101c24"), border := Color("465052")) -> Panel:
	var p := Panel.new()
	p.position = pos
	p.size = bounds
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	p.add_theme_stylebox_override("panel",style)
	parent.add_child(p)
	return p

func text(parent: Node, content: String, pos: Vector2, bounds: Vector2, font_size := 20, color := CREAM, heading := false, centered := false) -> Label:
	var l := Label.new()
	l.text = content
	l.position = pos
	l.size = bounds
	l.add_theme_font_size_override("font_size",font_size)
	l.add_theme_color_override("font_color",color)
	l.add_theme_font_override("font",serif if heading else sans)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if centered: l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func button(parent: Node, title: String, pos: Vector2, bounds: Vector2, action: Callable, primary := false) -> Button:
	var b := Button.new()
	b.text = title
	b.position = pos
	b.size = bounds
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size",18)
	b.add_theme_color_override("font_color",Color("1c2426") if primary else CREAM)
	b.add_theme_color_override("font_hover_color",Color("151c22") if primary else Color.WHITE)
	for key in ["normal","hover","pressed","focus","disabled"]:
		var s := StyleBoxFlat.new()
		s.bg_color = GOLD if primary else Color(0.045,0.08,0.1,0.92)
		if key in ["hover","focus"]: s.bg_color = s.bg_color.lightened(0.14)
		if key == "pressed": s.bg_color = s.bg_color.darkened(0.15)
		s.border_color = GOLD if primary else Color("62645b")
		s.set_border_width_all(1)
		s.set_corner_radius_all(5)
		b.add_theme_stylebox_override(key,s)
	b.pressed.connect(func():
		if not busy:
			sound.play("click")
			action.call()
	)
	parent.add_child(b)
	return b

func gradient(parent: Node, pos: Vector2, bounds: Vector2, top: Color, bottom: Color) -> void:
	var g := Gradient.new()
	g.colors = PackedColorArray([top,bottom])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0,0)
	tex.fill_to = Vector2(0,1)
	var r := TextureRect.new()
	r.texture = tex
	r.position = pos
	r.size = bounds
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)

func sprite(parent: Node, index: int, pos: Vector2, bounds: Vector2) -> TextureRect:
	var atlas := AtlasTexture.new()
	atlas.atlas = actor_texture
	var regions := [Rect2(24,0,475,512),Rect2(510,0,540,512),Rect2(1050,0,486,512),Rect2(0,510,512,514),Rect2(512,510,512,514),Rect2(960,490,576,534)]
	atlas.region = regions[index]
	icon(parent,"shadow",pos+Vector2(bounds.x*0.08,bounds.y-15),Vector2(bounds.x*0.84,32))
	var art := TextureRect.new()
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.texture = atlas
	var material := ShaderMaterial.new()
	material.shader = preload("res://ui/actor.gdshader")
	material.set_shader_parameter("region",Vector4(atlas.region.position.x/1536.0,atlas.region.position.y/1024.0,atlas.region.size.x/1536.0,atlas.region.size.y/1024.0))
	material.set_shader_parameter("motion",0.0 if reduced_motion else 1.0)
	material.set_shader_parameter("phase",float(index)*1.3)
	art.material = material
	art.position = pos
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.size = bounds
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(art)
	art.set_deferred("size",bounds)
	art.pivot_offset = Vector2(bounds.x/2,bounds.y)
	art.set_meta("origin",pos)
	if not reduced_motion:
		var tween := art.create_tween().set_loops()
		art.set_meta("idle_tween",tween)
		tween.tween_property(art,"scale",Vector2(1.008,1.015),1.5).set_trans(Tween.TRANS_SINE)
		tween.tween_property(art,"scale",Vector2.ONE,1.5).set_trans(Tween.TRANS_SINE)
	return art

func show_menu() -> void:
	in_menu = true
	busy = false
	clear_page()
	panel(page,Vector2(0,0),Vector2(770,900),Color(0.025,0.04,0.055,0.85),Color(0,0,0,0))
	text(page,"UN DECKBUILDER POLITIQUE · DÉMO 0.2",Vector2(84,66),Vector2(630,28),16,GOLD)
	text(page,"SLAY THE",Vector2(80,151),Vector2(680,75),58,CREAM,true)
	text(page,"EXTRÊME\nDROITE",Vector2(80,224),Vector2(710,180),70,CREAM,true)
	text(page,"Un jeu conçu par kingrabbit",Vector2(86,436),Vector2(600,40),25,GREEN)
	var pitch := text(page,"La nuit tombe sur le Grand Débat.\nPrenez la parole. Construisez vos enchaînements.\nFaites taire la Machine à peur.",Vector2(86,503),Vector2(630,102),23,MUTED)
	pitch.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button(page,"ENTRER DANS LE DÉBAT  →",Vector2(86,641),Vector2(410,62),new_run,true)
	if not saved_code.is_empty():
		button(page,"Reprendre la traversée",Vector2(86,719),Vector2(270,48),resume_run)
	button(page,"Comment jouer",Vector2(86,786),Vector2(198,44),show_help)
	button(page,"Les 20 cartes",Vector2(299,786),Vector2(198,44),func(): show_collection(core.catalog(),"Les cartes de Mathilde"))
	sprite(page,0,Vector2(917,228),Vector2(520,534))
	text(page,"MATHILDE PANOT",Vector2(920,775),Vector2(520,40),28,CREAM,true,true)
	text(page,"Amendements & enchaînements",Vector2(850,821),Vector2(660,30),18,GREEN,false,true)
	text(page,"1 personnage · 3 combats · 20 cartes · environ 10 minutes",Vector2(86,854),Vector2(800,25),14,MUTED)
	button(page,"Son : " + ("OFF" if sound.muted else "ON"),Vector2(1400,32),Vector2(150,40),toggle_sound)

func new_run() -> void:
	core.new_run(int(Time.get_unix_time_from_system()) % 1000000 + 1)
	in_menu = false
	journal.clear()
	render_state()
	checkpoint()

func resume_run() -> void:
	var err: String = core.load_code(saved_code)
	if err != "":
		toast(err)
		return
	in_menu = false
	render_state()

func checkpoint() -> void:
	var code: String = core.save_code() if not in_menu else ""
	if not code.is_empty(): saved_code = code
	var cfg := ConfigFile.new()
	cfg.set_value("run","code",saved_code)
	cfg.set_value("settings","muted",sound.muted)
	cfg.set_value("settings","reduced_motion",reduced_motion)
	cfg.set_value("settings","music",sound.music_level)
	cfg.set_value("settings","effects",sound.effects_level)
	DirAccess.make_dir_recursive_absolute(checkpoint_path.get_base_dir())
	cfg.save(checkpoint_path)

func toggle_sound() -> void:
	sound.toggle()
	checkpoint()
	if is_instance_valid(mute_button): mute_button.text = "Son : " + ("OFF" if sound.muted else "ON")
	elif in_menu: show_menu()

func icon(parent: Node,key: String,pos: Vector2,bounds: Vector2) -> TextureRect:
	var r := TextureRect.new()
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.texture = load("res://assets/ui/%s.svg" % key)
	r.position = pos
	r.size = bounds
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r

func icon_button(key: String,pos: Vector2,bounds: Vector2,hint: String,action: Callable) -> Button:
	var b := button(page,"",pos,bounds,action)
	for style_name in ["normal","hover","pressed","focus"]:
		b.add_theme_stylebox_override(style_name,StyleBoxEmpty.new())
	icon(b,key,Vector2.ZERO,bounds)
	b.tooltip_text = hint
	b.mouse_entered.connect(func(): b.modulate = Color(1.35,1.3,1.1))
	b.mouse_exited.connect(func(): b.modulate = Color.WHITE)
	return b

func hud() -> void:
	panel(page,Vector2.ZERO,Vector2(1600,55),Color(0.055,0.12,0.15,0.97),Color("626f6b"))
	text(page,"MATHILDE",Vector2(25,10),Vector2(150,32),18,GOLD,true)
	icon(page,"heart",Vector2(187,12),Vector2(31,31))
	text(page,"%d / %d" % [state.hp,state.max_hp],Vector2(224,11),Vector2(120,32),21,RED)
	icon(page,"coin",Vector2(365,12),Vector2(30,30))
	text(page,str(state.gold),Vector2(405,11),Vector2(90,32),22,GOLD)
	text(page,"LA PLACE DES VOIX    /    ÉTAPE %d" % (state.floor+1),Vector2(570,13),Vector2(500,30),16,MUTED,false,true)
	icon_button("deck",Vector2(1190,5),Vector2(38,45),"Deck · %d cartes [D]" % state.deck.size(),func(): show_collection(state.deck,"Votre deck"))
	icon_button("map",Vector2(1270,9),Vector2(36,36),"Règles et parcours",show_help)
	icon_button("sound",Vector2(1360,9),Vector2(36,36),"Activer / couper le son [M]",toggle_sound)
	icon_button("gear",Vector2(1510,7),Vector2(40,40),"Pause et volumes [Échap]",show_pause)
	icon_button("relic",Vector2(27,68),Vector2(46,46),"Le perchoir : la troisième carte du tour donne 3 Bloc.",func(): toast("Le perchoir : troisième carte du tour → +3 Bloc."))
	if state.relic:
		icon_button("shield",Vector2(85,72),Vector2(37,40),"Écharpe solidaire : +5 Bloc au début du combat.",func(): toast("Écharpe solidaire : +5 Bloc au premier tour."))

func render_state() -> void:
	state = core.snapshot()
	clear_page()
	hud()
	match state.phase:
		"map": draw_map()
		"combat": draw_combat()
		"reward": draw_rewards()
		"rest": draw_rest()
		"won", "lost": draw_end()

func draw_map() -> void:
	text(page,"ACTE I  /  LA PLACE DES VOIX",Vector2(0,130),Vector2(1600,35),17,GOLD,false,true)
	text(page,"Une voix dans la nuit",Vector2(0,178),Vector2(1600,65),44,CREAM,true,true)
	text(page,"Chaque débat vous transforme. Choisissez les arguments que vous emporterez.",Vector2(0,253),Vector2(1600,35),21,MUTED,false,true)
	panel(page,Vector2(195,430),Vector2(1210,3),Color("7b7763"),Color("7b7763"))
	var names := ["La rumeur","Le plateau","La permanence","Le Grand Débat"]
	var subtitles := ["Premier combat","Choix de parcours","Soin ou amélioration","Boss · Machine à peur"]
	var glyphs := ["I","II","III","IV"]
	for i in 4:
		var x := 210.0+i*345
		var active: bool = i == state.floor
		var done: bool = i < state.floor
		var p := panel(page,Vector2(x-75,360),Vector2(200,145),Color("1a302f") if active else Color("111e26"),GOLD if active else Color("4a5453"))
		text(p,"✓" if done else glyphs[i],Vector2(0,12),Vector2(200,70),43,GREEN if done else GOLD,true,true)
		text(p,"ACCOMPLI" if done else ("PROCHAINE ÉTAPE" if active else "À VENIR"),Vector2(0,100),Vector2(200,25),12,GREEN if active else MUTED,false,true)
		text(page,names[i],Vector2(x-125,522),Vector2(300,42),25,CREAM,true,true)
		text(page,subtitles[i],Vector2(x-140,568),Vector2(330,30),16,MUTED,false,true)
	if state.floor == 1:
		button(page,"Le face-à-face\n1 adversaire",Vector2(458,636),Vector2(320,78),func(): enter_room(0),true)
		var b := button(page,"Le plateau hostile\n2 adversaires · relique bonus",Vector2(820,636),Vector2(320,78),func(): enter_room(1))
		b.tooltip_text = "Écharpe solidaire : +5 Bloc au premier tour des combats suivants."
	else:
		button(page,"REJOINDRE LA PROCHAINE ÉTAPE  →",Vector2(550,653),Vector2(500,64),func(): enter_room(0),true)
	text(page,"Sauvegarde automatique entre les étapes  ·  Graine %d" % state.seed,Vector2(0,817),Vector2(1600,30),15,MUTED,false,true)

func enter_room(route: int) -> void:
	checkpoint()
	perform("enter_room",[route])

func draw_combat() -> void:
	text(page,"Tour %d" % state.turn,Vector2(1380,74),Vector2(180,30),20,GOLD,true,true)
	text(page,"%d cartes · %d amendements" % [state.played,state.amendments],Vector2(1270,109),Vector2(290,25),14,MUTED,false,true)
	gradient(page,Vector2(0,660),Vector2(1600,240),Color(0.01,0.025,0.035,0),Color(0.01,0.025,0.035,0.8))
	actors.append(sprite(page,0,Vector2(282,303),Vector2(310,320)))
	stat_bar(Vector2(327,635),220,state.hp,state.max_hp,"Mathilde Panot",state.block,true)
	for i in state.powers.size():
		var power: Dictionary = state.powers[i]
		var b := icon_button("power",Vector2(335+i*38,666),Vector2(30,30),power.name+" : "+power.description,func(): toast(power.description))
		b.modulate = Color("c7a3ee")
	for i in state.enemies.size():
		var e: Dictionary = state.enemies[i]
		var x: float = 1120.0 if state.enemies.size()==1 else 970.0+i*330
		var width := 330.0 if e.sprite==5 else 275.0
		var pos := Vector2(x-width/2,286 if e.sprite==5 else 325)
		var bounds := Vector2(width,335 if e.sprite==5 else 300)
		var actor := sprite(page,e.sprite,pos,bounds)
		actors.append(actor)
		stat_bar(Vector2(x-110,635),220,e.hp,e.max_hp,e.name,e.block,false)
		if e.hp<=0:
			actor.modulate = Color(0.35,0.35,0.4,0.1)
			continue
		var target := Button.new()
		target.position = pos
		target.size = bounds
		target.flat = true
		target.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		target.tooltip_text = "Cliquez pour cibler après avoir sélectionné une attaque."
		target.pressed.connect(func(): target_enemy(i))
		target.mouse_entered.connect(func(): actor.self_modulate = Color(1.25,1.17,1.0))
		target.mouse_exited.connect(func(): actor.self_modulate = Color.WHITE)
		page.add_child(target)
		var intent: String = "%d dégâts" % e.damage if e.damage>0 else "+%d Bloc" % e.intent_block
		if e.hits>1: intent = "%d × %d dégâts" % [e.damage,e.hits]
		if e.noise>0: intent += " · Brouhaha"
		if e.get("intent_strength",0)>0: intent += " · +%d Force" % e.intent_strength
		var ib := icon_button("sword" if e.damage>0 else "shield",Vector2(x-35,pos.y-70),Vector2(48,48),e.intent+" : "+intent,func(): toast(e.intent+" : "+intent))
		ib.modulate = Color("ffb8a5") if e.damage>0 else Color("a3e9f1")
		text(page,str(e.damage) + (" × %d" % e.hits if e.hits>1 else "") if e.damage>0 else str(e.intent_block),Vector2(x+13,pos.y-59),Vector2(110,35),25,CREAM)
		text(page,e.intent,Vector2(x-140,pos.y-98),Vector2(280,25),14,MUTED,false,true)
		if e.noise>0 or e.get("intent_strength",0)>0:
			text(page,intent,Vector2(x-150,pos.y-22),Vector2(300,23),13,GOLD,false,true)
		var status_x: float = x-70
		for status in [["weak",e.weak,"Faiblesse"],["vulnerable",e.vulnerable,"Vulnérable"],["sword",e.strength,"Force"]]:
			if status[1]>0:
				icon_button(status[0],Vector2(status_x,663),Vector2(26,26),"%s : %d" % [status[2],status[1]],func(): toast("%s : %d" % [status[2],status[1]]))
				text(page,str(status[1]),Vector2(status_x+25,668),Vector2(24,20),14,GOLD)
				status_x += 55
	icon(page,"energy",Vector2(55,699),Vector2(139,139))
	energy_label = text(page,"%d / 3" % state.energy,Vector2(55,737),Vector2(139,56),35,CREAM,true,true)
	var draw_button := icon_button("draw-pile",Vector2(12,805),Vector2(65,78),"Pioche : %d cartes (ordre masqué)" % state.draw.size(),func(): show_collection(sorted_pile(state.draw),"Pioche · ordre masqué"))
	text(draw_button,str(state.draw.size()),Vector2(45,45),Vector2(45,30),23,CREAM)
	var end := icon_button("end-turn",Vector2(1365,738),Vector2(220,80),"Terminer le tour [E]",func(): perform("end_turn",[]))
	text(end,"Fin du tour",Vector2(22,22),Vector2(176,35),23,CREAM,true,true)
	var discard_button := icon_button("discard-pile",Vector2(1508,805),Vector2(65,78),"Défausse : %d cartes" % state.discard.size(),func(): show_collection(state.discard,"Défausse"))
	text(discard_button,str(state.discard.size()),Vector2(-20,44),Vector2(45,30),23,CREAM)
	var exhaust_button := icon_button("fire",Vector2(1530,675),Vector2(35,40),"Épuisées : %d cartes" % state.exhaust.size(),func(): show_collection(state.exhaust,"Épuisées · hors du combat"))
	text(exhaust_button,str(state.exhaust.size()),Vector2(-25,12),Vector2(25,25),16,MUTED)
	help_label = text(page,"Sélectionnez une carte, puis sa cible.",Vector2(475,80),Vector2(650,26),14,MUTED,false,true)
	var count: int = state.hand.size()
	deal_finish = 0.0
	var gap: float = minf(157.0,1030.0/maxf(1,count-1))
	var start: float = 800.0-(gap*(count-1)+200)/2.0
	for i in count:
		var c := CardView.new()
		c.setup(state.hand[i])
		var offset: float = i-(count-1)/2.0
		c.position = Vector2(start+i*gap,700+absf(offset)*absf(offset)*4)
		c.base_position = c.position
		c.base_rotation = deg_to_rad(offset*3.3)
		c.rotation = c.base_rotation
		c.base_z = i
		c.z_index = i
		c.add_theme_font_override("font",sans)
		if state.hand[i].cost>state.energy or state.hand[i].cost<0: c.modulate = Color(0.58,0.62,0.64,1)
		c.pressed.connect(func(): choose_hand(i))
		page.add_child(c)
		hand_views.append(c)
		if animate_hand and not reduced_motion:
			if not draw_all and hand_origins.has(c.data.uid):
				c.position = hand_origins[c.data.uid]
				c.lift = c.create_tween()
				c.lift.tween_property(c,"position",c.base_position,0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			else:
				deal_finish = maxf(deal_finish,i*0.075+0.38)
				deal_card(c,i*0.075)
	animate_hand = false
	draw_all = false
	hand_origins.clear()
	if state.pending != "": show_choice()

func stat_bar(pos: Vector2,width: float,hp: int,max_hp: int,name_text: String,block: int,_hero: bool) -> void:
	text(page,name_text,pos-Vector2(15,29),Vector2(width+30,24),17,CREAM,true,true)
	panel(page,pos,Vector2(width,13),Color("2c2227"),Color("937361"))
	var fill := panel(page,pos+Vector2(2,2),Vector2(maxf(0.01,(width-4)*float(hp)/max_hp),9),Color("b93442"),Color(0,0,0,0))
	var number := text(page,"%d / %d" % [hp,max_hp],pos-Vector2(0,5),Vector2(width,22),13,CREAM,false,true)
	number.add_theme_constant_override("outline_size",3)
	number.add_theme_color_override("font_outline_color",Color("281e24"))
	var shield := icon(page,"shield",pos+Vector2(-39,-15),Vector2(36,42))
	var shield_text := text(page,str(block),pos+Vector2(-39,-12),Vector2(36,35),20,CREAM,false,true)
	shield.visible = block>0
	shield_text.visible = block>0
	bar_views.append({"fill":fill,"number":number,"shield":shield,"block":shield_text,"width":width})
	shown_stats.append({"hp":hp,"max_hp":max_hp,"block":block})

func update_bar(index: int) -> void:
	if index>=bar_views.size(): return
	var stats: Dictionary = shown_stats[index]
	var bar: Dictionary = bar_views[index]
	create_tween().tween_property(bar.fill,"size:x",maxf(0.01,(bar.width-4)*float(stats.hp)/stats.max_hp),0.17)
	bar.number.text = "%d / %d" % [stats.hp,stats.max_hp]
	bar.shield.visible = stats.block>0
	bar.block.visible = stats.block>0
	bar.block.text = str(stats.block)

func sorted_pile(cards: Array) -> Array:
	var sorted := cards.duplicate()
	sorted.sort_custom(func(a,b): return a.id < b.id)
	return sorted

func choose_hand(index: int) -> void:
	if busy or overlay.get_child_count()>0 or state.phase!="combat": return
	if index>=state.hand.size(): return
	var c: Dictionary = state.hand[index]
	if c.cost<0:
		toast("Brouhaha est injouable et s'épuise à la fin du tour.")
		return
	if c.cost>state.energy:
		toast("Énergie insuffisante.")
		return
	if c.kind=="Attaque" or c.id==7:
		selected = index
		for i in hand_views.size(): hand_views[i].select(i==index)
		help_label.text = "%s  →  Choisissez un adversaire" % c.name
		help_label.add_theme_color_override("font_color",GOLD)
		sound.play("paper")
	else:
		perform("play_card",[index,first_living()])

func first_living() -> int:
	for i in state.enemies.size():
		if state.enemies[i].hp>0: return i
	return 0

func target_enemy(index: int) -> void:
	if busy or overlay.get_child_count()>0: return
	if selected<0:
		toast("Sélectionnez d'abord une carte Attaque dans votre main.")
		return
	perform("play_card",[selected,index])

func _process(_delta: float) -> void:
	if not is_instance_valid(vfx): return
	vfx.aim = selected>=0 and not busy and overlay.get_child_count()==0 and selected<hand_views.size()
	if vfx.aim:
		vfx.aim_from = hand_views[selected].position+Vector2(100,0)
		vfx.aim_to = get_global_mouse_position()

func perform(method: String,args: Array) -> void:
	if busy: return
	busy = true
	var previous: Dictionary = state.duplicate(true)
	var err: String = core.callv(method,args)
	if not err.is_empty():
		busy = false
		toast(err)
		return
	var next: Dictionary = core.snapshot()
	if is_instance_valid(help_label): help_label.text = ""
	if is_instance_valid(energy_label):
		energy_label.text = "%d / 3" % (0 if method=="end_turn" else next.energy)
	hand_origins.clear()
	for c in hand_views:
		hand_origins[c.data.uid] = c.base_position
		c.interactive = false
		if c.lift: c.lift.kill()
	var played: Control = null
	if method=="play_card" and args[0]<hand_views.size():
		played = hand_views[args[0]]
		played.reparent(fx)
		played.z_index = 0
		played.mouse_filter = Control.MOUSE_FILTER_IGNORE
		played.modulate = Color.WHITE
		await fly_card(played,Vector2(750,345),Vector2.ONE*0.8,0.19,false)
	if method=="end_turn":
		turn_banner("Tour adverse","",RED)
		for i in hand_views.size():
			var c: Control = hand_views[i]
			c.reparent(fx)
			c.z_index = 0
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
			retire_card(c,next)
		await get_tree().create_timer(0.36 if not reduced_motion else 0.08).timeout
	if method in ["play_card","end_turn"]:
		await present_events(next.events)
	if is_instance_valid(played):
		retire_card(played,next)
		await get_tree().create_timer(0.12).timeout
	if next.phase in ["won","lost","reward"] and previous.phase=="combat":
		turn_banner("Débat remporté" if next.phase!="lost" else "Fin du débat","",GOLD)
		await get_tree().create_timer(0.65).timeout
	animate_hand = next.phase=="combat"
	draw_all = method in ["enter_room","end_turn"]
	if method=="enter_room" and next.phase=="combat":
		turn_banner("À vous de jouer","Tour 1",GOLD)
	render_state()
	if animate_hand: animate_hand = false
	if state.phase=="combat" and not reduced_motion:
		await get_tree().create_timer(maxf(0.2,deal_finish)).timeout
	busy = false
	if state.phase=="map": checkpoint()
	if state.phase in ["won","lost"]:
		saved_code = ""
		checkpoint()

func fly_card(c: Control,destination: Vector2,final_scale: Vector2,duration: float,trail := true) -> void:
	var origin := c.position
	var old_scale := c.scale
	var old_rotation := c.rotation
	if reduced_motion: duration = 0.07
	if trail: vfx.emit("trail",origin+c.size*0.5,Color("ff9b36"),duration,destination+c.size*0.5)
	var t := c.create_tween()
	t.tween_method(func(progress: float):
		c.position = CombatFx.arc(origin,destination,progress) if not reduced_motion else origin.lerp(destination,progress)
		c.scale = old_scale.lerp(final_scale,progress)
		c.rotation = lerpf(old_rotation,0.0,progress)
	,0.0,1.0,duration)
	await t.finished

func retire_card(c: Control,next: Dictionary) -> void:
	var exhausted := false
	for card in next.exhaust:
		if card.uid==c.data.uid: exhausted = true
	var power: bool = c.data.kind=="Pouvoir"
	if exhausted or power:
		vfx.burst(c.position+c.size*0.5,Color("d1b0ff") if power else GOLD,32)
		vfx.emit("ring",c.position+c.size*0.5,GOLD,0.5)
		var t := c.create_tween().set_parallel(true)
		t.tween_property(c,"modulate:a",0.0,0.3)
		t.tween_property(c,"scale",Vector2.ONE*0.2,0.3)
		await t.finished
	else:
		await fly_card(c,Vector2(1450,755),Vector2.ONE*0.16,0.42)
	c.queue_free()

func deal_card(c: Control,delay: float) -> void:
	c.interactive = false
	c.visible = false
	await get_tree().create_timer(delay).timeout
	if not is_instance_valid(c): return
	c.position = Vector2(-30,745)
	c.scale = Vector2.ONE*0.18
	c.rotation = -0.4
	c.visible = true
	if delay==0 and "--smoke" in OS.get_cmdline_user_args(): delayed_capture("deal",0.2)
	sound.play("paper")
	await fly_card(c,c.base_position,Vector2.ONE,0.38)
	if not is_instance_valid(c): return
	c.rotation = c.base_rotation
	c.interactive = true

func turn_banner(title: String,subtitle: String,color: Color) -> void:
	var l := text(fx,title,Vector2(450,240),Vector2(700,80),47,color,true,true)
	l.add_theme_constant_override("outline_size",9)
	l.add_theme_color_override("font_outline_color",Color("101b1b"))
	l.pivot_offset = l.size/2
	var sub := text(l,subtitle,Vector2(0,78),Vector2(700,28),20,CREAM,false,true)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.modulate.a = 0
	l.scale = Vector2.ONE*0.93
	var t := l.create_tween().set_parallel(true)
	t.tween_property(l,"modulate:a",1.0,0.15)
	t.tween_property(l,"scale",Vector2.ONE,0.25)
	t.chain().tween_interval(0.55)
	t.chain().tween_property(l,"modulate:a",0.0,0.3)
	t.chain().tween_callback(l.queue_free)

func present_events(events: Array) -> void:
	var attacker := 1
	for e in events:
		if not e.text.is_empty():
			journal.append(e.text)
			if journal.size()>80: journal.pop_front()
		var target: int = int(e.target)+1
		var pos := actor_center(target)
		match e.kind:
			"attack":
				sound.play("paper")
				set_pose(1)
				if not actors.is_empty(): lunge(actors[0],Vector2(52,0))
				await get_tree().create_timer(0.15).timeout
			"hit":
				sound.play("attack")
				vfx.emit("slash",pos,Color("ff7550"),0.32)
				vfx.burst(pos,Color("ffbf76"))
				floating(e.text,pos-Vector2(0,85),CREAM,49)
				if target>0 and target<actors.size():
					flash_actor(actors[target])
					lunge(actors[target],Vector2(14,0))
					var absorbed: int = mini(shown_stats[target].block,e.amount)
					shown_stats[target].block -= absorbed
					shown_stats[target].hp = maxi(0,shown_stats[target].hp-e.amount+absorbed)
					update_bar(target)
				screen_shake(5)
				await get_tree().create_timer(0.09).timeout
				if "--smoke" in OS.get_cmdline_user_args(): await screenshot("impact")
				await get_tree().create_timer(0.10).timeout
			"block":
				sound.play("block")
				set_pose(2)
				vfx.emit("shield",actor_center(0),Color("71d5f1"),0.65)
				vfx.burst(actor_center(0),Color("95e8ff"),12)
				floating("+%d" % e.amount,actor_center(0)-Vector2(0,65),Color("9ce9ff"),34)
				if not shown_stats.is_empty():
					shown_stats[0].block += e.amount
					update_bar(0)
				await get_tree().create_timer(0.18).timeout
				if "--smoke" in OS.get_cmdline_user_args(): await screenshot("shield")
			"relic", "power":
				sound.play("power")
				vfx.emit("ring",Vector2(50,90),GOLD,0.7)
				vfx.emit("ring",actor_center(0),Color("d4b2f5"),0.6)
				floating(e.text,actor_center(0)-Vector2(0,160),GOLD,23)
			"enemy":
				attacker = target
				floating(e.text,pos-Vector2(0,120),GOLD,21)
				if target>0 and target<actors.size(): lunge(actors[target],Vector2(-48,0))
				await get_tree().create_timer(0.19).timeout
				if target>0 and state.enemies[target-1].damage>0:
					vfx.emit("trail",pos,Color("f07157"),0.22,actor_center(0))
					await get_tree().create_timer(0.22).timeout
			"hurt":
				sound.play("hurt" if e.amount>0 else "block")
				var hero := actor_center(0)
				var blocked: bool = e.amount<=0
				vfx.emit("shield" if blocked else "slash",hero,Color("86dcf3") if blocked else RED,0.4)
				vfx.burst(hero,Color("9ce9ff") if blocked else Color("ff9e72"),20)
				floating(e.text,hero-Vector2(0,90),Color("9ce9ff") if blocked else RED,43)
				if not actors.is_empty() and not blocked:
					flash_actor(actors[0])
					lunge(actors[0],Vector2(-16,0))
					screen_shake(7)
				if not shown_stats.is_empty():
					shown_stats[0].hp = maxi(0,shown_stats[0].hp-e.amount)
					if attacker>0 and attacker<=state.enemies.size():
						shown_stats[0].block = maxi(0,shown_stats[0].block-state.enemies[attacker-1].damage)
					update_bar(0)
				await get_tree().create_timer(0.1).timeout
				if "--smoke" in OS.get_cmdline_user_args(): await screenshot("enemy-impact")
				await get_tree().create_timer(0.18).timeout
			"debuff":
				vfx.emit("ring",pos,Color("d796c7"),0.55)
				floating(e.text,pos-Vector2(0,110),GOLD,22)
			"death":
				if target>0 and target<actors.size():
					var actor: TextureRect = actors[target]
					if actor.has_meta("idle_tween"): actor.get_meta("idle_tween").kill()
					vfx.emit("death",pos,GOLD,0.7)
					vfx.burst(pos,Color("b9a589"),36)
					var t := actor.create_tween().set_parallel(true)
					t.tween_property(actor,"modulate",Color(0.15,0.12,0.15,0.0),0.55)
					if not reduced_motion:
						t.tween_property(actor,"position:y",actor.position.y+35,0.55)
						t.tween_property(actor,"rotation",0.12,0.55)
					await get_tree().create_timer(0.3).timeout
			"shuffle":
				vfx.emit("trail",Vector2(1530,850),Color("ffa340"),0.65,Vector2(45,850))
				sound.play("paper")
			"turn":
				turn_banner("À vous de jouer","Tour %d" % core.snapshot().turn,GOLD)
				set_pose(0)
			"noise":
				vfx.burst(Vector2(1530,820),Color("b2a1c5"),12)
			"victory": sound.play("victory")
			"defeat": sound.play("defeat")
	await get_tree().create_timer(0.12).timeout

func actor_center(index: int) -> Vector2:
	if index<0 or index>=actors.size(): return Vector2(435,455)
	return actors[index].position+actors[index].size*Vector2(0.5,0.47)

func set_pose(index: int) -> void:
	if actors.is_empty(): return
	var pose := AtlasTexture.new()
	pose.atlas = actor_texture
	pose.region = [Rect2(24,0,475,512),Rect2(510,0,540,512),Rect2(1050,0,486,512)][index]
	actors[0].texture = pose
	actors[0].material.set_shader_parameter("region",Vector4(pose.region.position.x/1536.0,pose.region.position.y/1024.0,pose.region.size.x/1536.0,pose.region.size.y/1024.0))

func screen_shake(strength: float) -> void:
	if reduced_motion: return
	if shake: shake.kill()
	shake = create_tween()
	for i in 4:
		shake.tween_property(page,"position",Vector2((1 if i%2==0 else -1)*strength/(i+1),strength*0.35/(i+1)),0.035)
	shake.tween_property(page,"position",Vector2.ZERO,0.04)

func lunge(actor: TextureRect,offset: Vector2) -> void:
	if reduced_motion: return
	if actor.has_meta("movement"): actor.get_meta("movement").kill()
	var origin: Vector2 = actor.get_meta("origin",actor.position)
	var t := actor.create_tween()
	actor.set_meta("movement",t)
	t.tween_property(actor,"position",origin-offset*0.23,0.07).set_trans(Tween.TRANS_SINE)
	t.tween_property(actor,"position",origin+offset,0.09).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_interval(0.055)
	t.tween_property(actor,"position",origin,0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func flash_actor(actor: TextureRect) -> void:
	actor.modulate = Color(2.0,0.7,0.55)
	create_tween().tween_property(actor,"modulate",Color.WHITE,0.23)

func floating(content: String,pos: Vector2,color: Color,font_size: int) -> void:
	var l := text(fx,content,pos-Vector2(150,0),Vector2(300,52),font_size,color,false,true)
	l.add_theme_color_override("font_outline_color",Color("101519"))
	l.add_theme_constant_override("outline_size",5)
	var t := create_tween().set_parallel(true)
	t.tween_property(l,"position:y",l.position.y-65,0.8)
	t.tween_property(l,"modulate:a",0.0,0.7).set_delay(0.2)
	t.chain().tween_callback(l.queue_free)

func paper_burst(from: Vector2,to: Vector2) -> void:
	if reduced_motion: return
	for i in 9:
		var p := ColorRect.new()
		p.color = Color("f0e3bc") if i%2==0 else GREEN
		p.position = from+Vector2(0,randf_range(-45,45))
		p.size = Vector2(randf_range(10,25),randf_range(5,12))
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fx.add_child(p)
		var t := create_tween().set_parallel(true)
		t.tween_property(p,"position",to+Vector2(randf_range(-65,65),randf_range(-90,90)),0.32)
		t.tween_property(p,"rotation",randf_range(-4,4),0.4)
		t.tween_property(p,"modulate:a",0.0,0.2).set_delay(0.23)
		t.chain().tween_callback(p.queue_free)

func draw_rewards() -> void:
	text(page,"DÉBAT REMPORTÉ",Vector2(0,132),Vector2(1600,35),18,GREEN,false,true)
	text(page,"Un nouvel argument",Vector2(0,185),Vector2(1600,65),46,CREAM,true,true)
	text(page,"Choisissez une carte à ajouter à votre deck, ou gardez-le plus compact.",Vector2(0,264),Vector2(1600,35),21,MUTED,false,true)
	for i in state.offers.size():
		var c := CardView.new()
		c.setup(state.offers[i],Vector2(230,324))
		c.position = Vector2(385+i*300,356)
		c.base_position = c.position
		c.interactive = false
		c.pressed.connect(func(): perform("take_reward",[i]))
		page.add_child(c)
		button(page,"CHOISIR",Vector2(385+i*300,700),Vector2(230,47),func(): perform("take_reward",[i]),true)
	text(page,"+25 pièces" + ("   ·   Écharpe solidaire obtenue : +5 Bloc au début des prochains combats" if state.relic else ""),Vector2(100,780),Vector2(1400,28),18,GOLD,false,true)
	button(page,"Passer la récompense  →",Vector2(610,830),Vector2(380,43),func(): perform("take_reward",[-1]))

func draw_rest() -> void:
	panel(page,Vector2(245,165),Vector2(1110,620),Color(0.035,0.07,0.08,0.95),Color("7e795c"))
	text(page,"LA PERMANENCE",Vector2(245,212),Vector2(1110,30),17,GREEN,false,true)
	text(page,"Reprendre son souffle",Vector2(245,269),Vector2(1110,60),43,CREAM,true,true)
	text(page,"Derrière les rideaux tirés, une lumière reste allumée.\nPréparez votre dernière prise de parole.",Vector2(245,349),Vector2(1110,85),24,MUTED,false,true)
	text(page,"UNE SEULE PRÉPARATION",Vector2(245,470),Vector2(1110,30),15,GOLD,false,true)
	button(page,"SE REPOSER\nRécupérer 24 PV",Vector2(390,545),Vector2(365,100),func(): perform("rest",[-1]),true)
	button(page,"AFFÛTER UN ARGUMENT\nAméliorer une carte",Vector2(845,545),Vector2(365,100),func(): show_collection(state.deck,"Choisissez une carte à améliorer",true))
	text(page,"PV actuels : %d / 70" % state.hp,Vector2(245,699),Vector2(1110,30),19,RED,false,true)

func draw_end() -> void:
	var win: bool = state.phase=="won"
	panel(page,Vector2(240,165),Vector2(1120,615),Color(0.025,0.055,0.065,0.95),GOLD)
	text(page,"VICTOIRE" if win else "FIN DE LA TRAVERSÉE",Vector2(240,210),Vector2(1120,40),19,GREEN if win else RED,false,true)
	text(page,"Le dernier mot est à vous." if win else "Une voix peut se relever.",Vector2(240,285),Vector2(1120,75),45,CREAM,true,true)
	text(page,"La Machine à peur s'éteint. La place retrouve ses voix." if win else "Les intentions étaient visibles. Votre prochain deck sera différent.",Vector2(240,380),Vector2(1120,60),23,MUTED,false,true)
	text(page,"%d cartes jouées    /    %d dégâts infligés    /    %d PV restants" % [state.total_cards,state.total_damage,state.hp],Vector2(240,494),Vector2(1120,40),22,GOLD,false,true)
	button(page,"NOUVELLE TRAVERSÉE",Vector2(440,610),Vector2(340,65),new_run,true)
	button(page,"Retour au titre",Vector2(820,610),Vector2(340,65),show_menu)
	text(page,"Slay the Extrême Droite · Démo conçue par kingrabbit",Vector2(240,720),Vector2(1120,28),16,MUTED,false,true)

func modal(title: String) -> Panel:
	for c in overlay.get_children(): c.queue_free()
	var shade := ColorRect.new()
	shade.color = Color(0.005,0.015,0.025,0.90)
	shade.size = Vector2(1600,900)
	overlay.add_child(shade)
	var p := panel(overlay,Vector2(110,80),Vector2(1380,750),Color("102027"),Color("766f58"))
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	text(p,title,Vector2(40,24),Vector2(1210,55),32,CREAM,true)
	button(p,"Fermer  ×",Vector2(1185,28),Vector2(150,43),close_modal)
	return p

func close_modal() -> void:
	if not in_menu and state.get("pending","") != "":
		toast("Choisissez une carte pour terminer cet effet.")
		return
	for c in overlay.get_children(): c.queue_free()

func show_collection(cards: Array,title: String,upgrade := false) -> void:
	var p := modal(title)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(35,105)
	scroll.size = Vector2(1310,600)
	p.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation",22)
	grid.add_theme_constant_override("v_separation",25)
	scroll.add_child(grid)
	for i in cards.size():
		var c := CardView.new()
		c.setup(cards[i],Vector2(192,282))
		c.interactive = false
		grid.add_child(c)
		if upgrade:
			c.disabled = cards[i].plus
			c.pressed.connect(func(): perform("rest",[i]))
	if cards.is_empty(): text(p,"Aucune carte dans cette pile.",Vector2(40,150),Vector2(1200,60),23,MUTED)

func show_choice() -> void:
	var titles := {"discard":"Choisissez une carte à défausser", "exhaust":"Choisissez une carte à épuiser", "scry":"Choisissez une carte à piocher"}
	var p := modal(titles[state.pending])
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(35,120)
	scroll.size = Vector2(1310,580)
	p.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation",22)
	grid.add_theme_constant_override("v_separation",24)
	scroll.add_child(grid)
	for i in state.choices.size():
		var c := CardView.new()
		c.setup(state.choices[i])
		c.interactive = false
		c.pressed.connect(func(): perform("choose_card",[i]))
		grid.add_child(c)

func show_help() -> void:
	var p := modal("Prendre la parole")
	var sections := [
		["01  Lisez les intentions", "Au-dessus de chaque adversaire : sa prochaine action.\nLe Bloc absorbe les dégâts, puis disparaît au début de votre tour."],
		["02  Dépensez vos 3 énergies", "Cliquez une Attaque, puis l'adversaire. Les Compétences\nse jouent directement. La main non jouée part à la défausse."],
		["03  Enchaînez les Amendements", "Ces cartes gratuites donnent 2 Bloc et s'épuisent.\nVotre 3e carte du tour donne +3 Bloc grâce au Perchoir."],
		["04  Construisez votre deck", "Après chaque victoire, choisissez une carte. À la permanence,\nsoignez-vous ou améliorez un argument avant le boss."],
	]
	for i in sections.size():
		var x := 48.0+(i%2)*660
		var y := 135.0+int(i/2)*190
		text(p,sections[i][0],Vector2(x,y),Vector2(610,42),26,GOLD,true)
		text(p,sections[i][1],Vector2(x,y+55),Vector2(620,85),20,CREAM)
	text(p,"Faiblesse : attaques −25 %   ·   Vulnérable : dégâts reçus +50 %\nÉpuisement : carte retirée du combat   ·   Pouvoir : effet actif pour tout le combat (non cumulable)",Vector2(48,534),Vector2(1260,85),20,GREEN)
	text(p,"1–9 / 0 : cartes   ·   E : fin du tour   ·   D : deck   ·   Échap : annuler / pause   ·   F11 : plein écran   ·   M : son",Vector2(48,665),Vector2(1270,35),16,MUTED)

func show_pause() -> void:
	var p := modal("Une pause dans le débat")
	button(p,"Reprendre",Vector2(430,153),Vector2(500,58),close_modal,true)
	button(p,"Animations réduites : "+("OUI" if reduced_motion else "NON"),Vector2(430,240),Vector2(500,58),func():
		reduced_motion = not reduced_motion
		atmosphere.reduced_motion = reduced_motion
		vfx.reduced_motion = reduced_motion
		for actor in actors:
			actor.material.set_shader_parameter("motion",0.0 if reduced_motion else 1.0)
		if reduced_motion:
			for actor in actors:
				if actor.has_meta("idle_tween"): actor.get_meta("idle_tween").kill()
		checkpoint()
		show_pause()
	)
	button(p,"Journal du combat",Vector2(430,327),Vector2(500,58),show_journal)
	button(p,"Retour au titre",Vector2(430,414),Vector2(500,58),show_menu)
	text(p,"La reprise se fait avant le combat en cours.\nLes choix de récompense sont enregistrés en quittant l'écran de récompense.",Vector2(100,643),Vector2(1180,70),21,MUTED,false,true)

	text(p,"Planète Boum Boum · Planète brûlée",Vector2(430,488),Vector2(520,28),17,GOLD,false,true)
	for row in [["Musique",sound.music_level,0],["Bruitages",sound.effects_level,1]]:
		var y: float = 533+row[2]*48
		text(p,row[0],Vector2(310,y),Vector2(170,30),18,CREAM)
		var slider := HSlider.new()
		slider.position = Vector2(500,y+4)
		slider.size = Vector2(470,25)
		slider.min_value = 0
		slider.max_value = 1
		slider.step = 0.01
		slider.value = row[1]
		p.add_child(slider)
		var percent := text(p,"%d %%" % roundi(row[1]*100),Vector2(990,y),Vector2(90,30),18,MUTED)
		var music_slider: bool = row[2]==0
		slider.value_changed.connect(func(value):
			if music_slider: sound.set_music(value)
			else: sound.set_effects(value)
			percent.text = "%d %%" % roundi(value*100)
			checkpoint()
		)

func show_journal() -> void:
	var p := modal("Journal du combat")
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(45,110)
	scroll.size = Vector2(1285,580)
	p.add_child(scroll)
	var l := Label.new()
	l.text = "\n".join(journal)
	l.add_theme_font_size_override("font_size",20)
	scroll.add_child(l)

func toast(message: String) -> void:
	if is_instance_valid(toast_label): toast_label.queue_free()
	toast_label = text(fx,message,Vector2(200,92),Vector2(1200,65),22,GOLD,false,true)
	toast_label.add_theme_constant_override("outline_size",8)
	toast_label.add_theme_color_override("font_outline_color",Color("09141d"))
	var l := toast_label
	var t := create_tween()
	t.tween_interval(2.6)
	t.tween_property(l,"modulate:a",0.0,0.3)
	t.tween_callback(l.queue_free)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode==KEY_F11:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	if event.keycode==KEY_M:
		toggle_sound()
		return
	if busy: return
	if event.keycode==KEY_ESCAPE:
		if overlay.get_child_count()>0: close_modal()
		elif selected>=0:
			selected = -1
			for c in hand_views: c.select(false)
		elif not in_menu: show_pause()
		return
	if in_menu or overlay.get_child_count()>0: return
	if event.keycode==KEY_D: show_collection(state.deck,"Votre deck")
	if state.phase!="combat": return
	if event.keycode==KEY_E: perform("end_turn",[])
	if event.keycode>=KEY_1 and event.keycode<=KEY_9: choose_hand(event.keycode-KEY_1)
	if event.keycode==KEY_0: choose_hand(9)

func smoke_test() -> void:
	# Integration checks run against the actual Rust extension and rendered scene.
	await get_tree().process_frame
	await get_tree().process_frame
	await screenshot("menu")
	core.new_run(42)
	in_menu = false
	render_state()
	checkpoint()
	var original_save := saved_code
	check(FileAccess.file_exists(checkpoint_path))
	var saved := ConfigFile.new()
	check(saved.load(checkpoint_path)==OK)
	check(saved.get_value("run","code")==original_save)
	# Changing settings on the title screen must not overwrite the saved run.
	in_menu = true
	core.new_run(99)
	checkpoint()
	check(saved_code==original_save)
	check(core.load_code(original_save)=="")
	in_menu = false
	render_state()
	await get_tree().process_frame
	await screenshot("map")
	check(core.enter_room(0)=="")
	render_state()
	await get_tree().process_frame
	await screenshot("combat")
	check(state.hand.size()==5)
	show_help()
	await get_tree().process_frame
	await screenshot("help")
	close_modal()
	await get_tree().process_frame
	# Exercise the UI selection controller and asynchronous visual resolution.
	# Inject pointer events into the viewport, rather than invoking the button handler.
	var card_pos: Vector2 = hand_views[1].get_global_rect().get_center()
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.position = card_pos
	down.pressed = true
	get_viewport().push_input(down,true)
	var up := down.duplicate() as InputEventMouseButton
	up.pressed = false
	get_viewport().push_input(up,true)
	await get_tree().process_frame
	check(selected==1)
	await perform("play_card",[1,0])
	check(state.energy==2)
	check(state.enemies[0].hp==30)
	# Defense, enemy resolution, discarding, redealing and their counters must agree.
	await perform("play_card",[0,0])
	check(state.block==5 and state.energy==1)
	await perform("end_turn",[])
	check(state.turn==2 and state.hp==69 and state.energy==3)
	check(state.hand.size()==5 and not busy)
	var hover := InputEventMouseMotion.new()
	hover.position = hand_views[2].base_position+Vector2(95,60)
	hover.global_position = hover.position
	get_viewport().push_input(hover,true)
	await get_tree().create_timer(0.25).timeout
	check(hand_views[2].position.y<hand_views[2].base_position.y-90)
	await screenshot("hover")
	show_pause()
	await get_tree().process_frame
	await screenshot("audio-settings")
	check(sound.music.stream is AudioStreamMP3)
	check(sound.music.stream.loop and sound.music.playing)
	close_modal()
	await get_tree().process_frame
	# Reduced motion keeps gameplay identical and disables camera/projectile motion.
	reduced_motion = true
	vfx.reduced_motion = true
	var turn_before: int = state.turn
	await perform("end_turn",[])
	check(state.turn==turn_before+1 and page.position==Vector2.ZERO)
	reduced_motion = false
	vfx.reduced_motion = false
	await get_tree().process_frame
	# Replay a full winning run generated by the independent Rust test player.
	var captured := {}
	var tape := FileAccess.get_file_as_string("res://tests/winning_run.txt")
	for row in tape.split("\n",false):
		var parts := row.split(",")
		var args: Array = []
		for i in range(1,parts.size()): args.append(int(parts[i]))
		var result = core.callv(parts[0],args)
		if parts[0]!="new_run": check(result=="")
		state = core.snapshot()
		var phase: String = state.phase
		var key: String = "boss" if phase=="combat" and state.floor==3 else phase
		if key in ["reward","rest","boss","won"] and not captured.has(key):
			captured[key]=true
			render_state()
			await get_tree().process_frame
			await screenshot(key)
	check(core.snapshot().phase=="won")
	check(captured.size()==4)
	print("UI_SMOKE_OK: pointer, attack, block, enemy turn, discard/deal, reduced motion, MP3, settings; full Rust replay to victory")
	await get_tree().create_timer(1.0).timeout
	core = null
	get_tree().quit()

func delayed_capture(label_text: String,delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	await screenshot(label_text)

func showcase() -> void:
	# Repeatable audiovisual capture of a real battle, using only public commands.
	core.new_run(42)
	in_menu = false
	render_state()
	await perform("enter_room",[0])
	await get_tree().create_timer(0.7).timeout
	var hover := InputEventMouseMotion.new()
	hover.position = hand_views[1].base_position+Vector2(75,50)
	hover.global_position = hover.position
	get_viewport().push_input(hover,true)
	await get_tree().create_timer(0.6).timeout
	await perform("play_card",[1,0])
	await perform("play_card",[0,0])
	await get_tree().create_timer(0.35).timeout
	await perform("end_turn",[])
	var guard := 0
	while state.phase=="combat" and guard<40:
		guard += 1
		var playable := -1
		for i in state.hand.size():
			if state.hand[i].cost>=0 and state.hand[i].cost<=state.energy:
				playable = i
				if state.hand[i].kind=="Attaque": break
		if playable>=0:
			await perform("play_card",[playable,first_living()])
		else: await perform("end_turn",[])
		await get_tree().create_timer(0.18).timeout
	check(state.phase=="reward")
	await get_tree().create_timer(1.5).timeout
	print("SHOWCASE_OK")
	core = null
	sound.stop_all()
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()

func check(condition: bool) -> void:
	if not condition:
		push_error("UI_SMOKE_FAILED")
		get_tree().quit(1)

func screenshot(name_text: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	var qa_dir := ProjectSettings.globalize_path("res://../build/qa") if OS.has_feature("editor") else OS.get_executable_path().get_base_dir().path_join("../qa-export")
	DirAccess.make_dir_recursive_absolute(qa_dir)
	get_viewport().get_texture().get_image().save_png(qa_dir.path_join(name_text+".png"))
