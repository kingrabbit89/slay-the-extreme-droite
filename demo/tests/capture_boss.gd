extends SceneTree

# Capture actual boss gameplay for the trailer without touching player saves.
func _initialize() -> void:
	capture.call_deferred()

func capture() -> void:
	var ui = load("res://scenes/main.tscn").instantiate()
	root.add_child(ui)
	await process_frame
	ui.checkpoint_path = ProjectSettings.globalize_path("res://../build/trailer/capture.cfg")
	ui.in_menu = false
	var reached := false
	var played := 0
	for row in FileAccess.get_file_as_string("res://tests/winning_run.txt").split("\n",false):
		var parts := row.split(",")
		var args: Array = []
		for i in range(1,parts.size()): args.append(int(parts[i]))
		if not reached:
			ui.core.callv(parts[0],args)
			var snapshot: Dictionary = ui.core.snapshot()
			if snapshot.phase=="combat" and snapshot.floor==3:
				reached = true
				ui.render_state()
				await create_timer(1.1).timeout
		else:
			await ui.perform(parts[0],args)
			played += 1
			await create_timer(0.3).timeout
			if played>=7: break
	await create_timer(0.9).timeout
	print("BOSS_CAPTURE_OK")
	ui.core = null
	ui.sound.stop_all()
	await create_timer(0.2).timeout
	quit()
