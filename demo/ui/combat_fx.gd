extends Control

# Presentation only: lifetimes and trajectories never change the Rust simulation.
var effects: Array[Dictionary] = []
var reduced_motion := false
var aim := false
var aim_from := Vector2.ZERO
var aim_to := Vector2.ZERO
var clock := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func emit(kind: String,at: Vector2,color: Color,duration := 0.6,to := Vector2.ZERO) -> void:
	effects.append({"kind":kind,"at":at,"to":to,"color":color,"age":0.0,"life":duration})

func burst(at: Vector2,color: Color,count := 24) -> void:
	if reduced_motion: count = 5
	for i in count:
		var angle := randf()*TAU
		effects.append({"kind":"spark","at":at,"to":Vector2.from_angle(angle)*randf_range(60,280),"color":color,"age":0.0,"life":randf_range(0.25,0.65)})

static func arc(from: Vector2,to: Vector2,t: float) -> Vector2:
	var control := (from+to)*0.5-Vector2(0,minf(280,from.distance_to(to)*0.38))
	return from.lerp(control,t).lerp(control.lerp(to,t),t)

func _process(delta: float) -> void:
	clock += delta
	for e in effects: e.age += delta
	effects = effects.filter(func(e): return e.age<e.life)
	queue_redraw()

func _draw() -> void:
	for e in effects:
		var t: float = e.age/e.life
		var alpha: float = 1.0-t
		var p: Vector2 = e.at
		var color: Color = e.color
		match e.kind:
			"trail":
				if reduced_motion: continue
				var line := PackedVector2Array()
				for j in 18:
					line.append(arc(p,e.to,clampf(t-float(17-j)*0.012,0,1)))
				draw_polyline(line,Color(color,0.09),28,true)
				draw_polyline(line,Color(color,0.3),13,true)
				draw_polyline(line,Color(color,0.9),4,true)
				draw_circle(line[-1],6,Color("fff2bc"))
			"spark":
				var q: Vector2 = p+e.to*t+Vector2(0,70*t*t)
				draw_line(q-e.to.normalized()*12*alpha,q,Color(color,alpha),3*alpha+0.5,true)
			"slash":
				var a := p+Vector2(-100,65)
				var b := p+Vector2(100,-65)
				var q := a.lerp(b,minf(1,t*4))
				draw_line(a,q,Color(color,alpha*0.17),40*alpha,true)
				draw_line(a,q,Color(color,alpha),12*alpha,true)
				draw_line(a,q,Color(1,0.98,0.85,alpha),3*alpha,true)
				draw_arc(p,20+70*t,-0.7,3.7,32,Color(color,alpha*0.5),3,true)
			"shield":
				var k := 0.8+sin(t*PI)*0.25
				var poly := PackedVector2Array([p+Vector2(0,-85)*k,p+Vector2(64,-51)*k,p+Vector2(50,30)*k,p+Vector2(0,82)*k,p+Vector2(-50,30)*k,p+Vector2(-64,-51)*k,p+Vector2(0,-85)*k])
				draw_colored_polygon(poly,Color(color,alpha*0.12))
				draw_polyline(poly,Color(color,alpha*0.16),18,true)
				draw_polyline(poly,Color(color,alpha),3,true)
			"ring":
				draw_arc(p,20+100*t,0,TAU,64,Color(color,alpha),4*alpha,true)
				draw_circle(p,35+45*t,Color(color,0.09*alpha))
			"death":
				for j in 14:
					var a: float = float(j)/14*TAU
					draw_line(p+Vector2.from_angle(a)*(15+t*100),p+Vector2.from_angle(a)*(70+t*130),Color(color,alpha*0.6),2,true)
	if aim:
		var prev := aim_from
		for j in range(1,32):
			var q := arc(aim_from,aim_to,float(j)/31)
			if j%3!=0: draw_line(prev,q,Color("f1cf8a"),3,true)
			prev = q
		var direction := (aim_to-arc(aim_from,aim_to,0.95)).normalized()
		draw_colored_polygon(PackedVector2Array([aim_to,aim_to-direction*22+direction.orthogonal()*10,aim_to-direction*22-direction.orthogonal()*10]),Color("ffe3a4"))
		draw_arc(aim_to,20+sin(clock*5)*2,0,TAU,28,Color("f1cf8a"),2,true)
