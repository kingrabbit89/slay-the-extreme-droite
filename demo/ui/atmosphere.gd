extends Control

var time := 0.0
var motes: Array[Vector4] = []
var reduced_motion := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	for i in 60:
		motes.append(Vector4(rng.randf_range(0,1600),rng.randf_range(80,690),rng.randf_range(0.4,1.8),rng.randf_range(0,TAU)))

func _process(delta: float) -> void:
	if not reduced_motion:
		time += delta
		queue_redraw()

func _draw() -> void:
	for p in motes:
		var pos := Vector2(fposmod(p.x+time*8*p.z,1600),80+fposmod(p.y-time*5*p.z,610))
		draw_circle(pos,p.z,Color(0.95,0.7,0.35,0.12+0.14*sin(time+p.w)))
	for i in 3:
		var x := 790.0+i*240
		var offset := sin(time*0.18+i)*90
		draw_colored_polygon(PackedVector2Array([Vector2(x,100),Vector2(x-190+offset,690),Vector2(x+130+offset,690)]),Color(0.9,0.79,0.57,0.022))
