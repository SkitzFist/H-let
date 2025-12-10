package game
import "core:fmt"
import "core:math"
import "core:slice"
import "core:time"

import rl "vendor:raylib"


@(private = "file")
ButtonMap :: enum {
	SKILL_TREE,
}

Gameloop :: struct {
	buttons:   [ButtonMap]Button,
	on_button: int,
	actives:   Actives,
}

gameloop_create_default :: proc() -> Gameloop {
	gameloop: Gameloop = {
		buttons = {
			.SKILL_TREE = {
				text = "Skill tree",
				visible = true,
				func = proc() {switch_scene(.SKILL_TREE)},
				style = .NORMAL,
			},
		},
		actives = actives_create_default(),
	}
	return gameloop
}

gameloop_on_enter :: proc() {

}

game_loop_on_exit :: proc() {

}

gameloop_input :: proc() {
	gameloop := &g.gameloop
	actives := &gameloop.actives
	now := time.now()

	if rl.IsKeyPressed(rl.KeyboardKey.T) {
		switch_scene(.SKILL_TREE)
	}

	gameloop.on_button = button_input(slice.enumerated_array(&g.gameloop.buttons))
	if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) && gameloop.on_button != -1 {
		g.gameloop.buttons[ButtonMap(gameloop.on_button)].func()
	}

	active_button_index := button_input(slice.enumerated_array(&actives.buttons))
	if active_button_index != -1 && rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
		active_type := ActiveType(active_button_index)
		elapsed := time.diff(actives.cooldowns[active_type].last_used_at, now)
		can_use := elapsed >= actives.cooldowns[active_type].cooldown

		if can_use {
			gameloop.actives.cooldowns[active_type].last_used_at = time.now()
			//TODO when done prototyping, don't trigger actives from input, add to queue and trigger in update
			gameloop.actives.active_use[active_type]()
		}
	}

	if gameloop.on_button == -1 && active_button_index == -1 {
		hole_input(&g.holeManager)
	}

	if rl.IsKeyPressed(rl.KeyboardKey.PERIOD) {
		for i in 0 ..< 10_000 {
			objects_add_random()
		}
	}
}

curr: f32 = 0.0
//TODO refactor this entire mess
gameloop_update :: proc(dt: f32) {
	holeManager := &g.holeManager
	objects := &g.objects
	obj_stats := &g.objectStats
	skills := &g.skills
	resources := &g.resources
	gameloop := &g.gameloop

	//todo cleanup, should allocate from custom tmp allocator (custom impl)
	hole_to_remove := make([dynamic]bool, len(g.holeManager.holes), context.temp_allocator)
	obj_to_remove := make([dynamic]int, 0, context.temp_allocator)
	for &hole, i in holeManager.holes {
		if hole_to_remove[i] {
			continue
		}

		if hole_evaporate(&hole, &holeManager.stats, dt) {
			hole_to_remove[i] = true
		}

		hole_attract_objects(&hole, &holeManager.stats, objects, &obj_to_remove)

		#reverse for obj in obj_to_remove {

			resource_drop := objects[obj].resource_drop
			hole.resources_eaten[resource_drop.type] += resource_drop.value

			objects_remove(obj)
		}

		clear_dynamic_array(&obj_to_remove)

		for &other, oi in g.holeManager.holes {
			if i == oi || hole_to_remove[oi] {
				continue
			}

			if hole_attract_hole(&hole, &other) {
				if hole.size > other.size {
					hole_to_remove[oi] = true
					hole_eat_hole(&hole, &other, &g.holeManager.stats)

				} else {
					hole_to_remove[i] = true
					hole_eat_hole(&other, &hole, &g.holeManager.stats)
					continue
				}
			}
		}

		hole_apply_force(&hole, dt)
	}

	#reverse for shouldRemove, i in hole_to_remove {
		if shouldRemove {
			resource_gain_multi(resources, holeManager.holes[i].resources_eaten)
			hole_remove(holeManager, i)
		}
	}

	objects_apply_forces(objects.pos, objects.phys, len(objects), dt)

	curr += dt

	object_spawn_rate := obj_stats.spawn_rate / skills.float[.OBJECT_SPAWN_RATE]
	for curr >= object_spawn_rate {
		objects_add_random()
		curr -= object_spawn_rate
	}

	//set button position
	button := &gameloop.buttons[.SKILL_TREE]
	button_width := f32(rl.GetRenderWidth()) * 0.075
	button_height := f32(rl.GetRenderHeight()) * 0.035
	button.x = f32(rl.GetRenderWidth() / 2) - (button_width / 2) - button_width
	button.y = f32(rl.GetRenderHeight()) - (button_height * 1.5)
	button.width = button_width
	button.height = button_height
}

gameloop_render :: proc() #no_bounds_check {
	textures := &g.textures
	objects := &g.objects
	pos := &objects.pos
	size := &objects.size
	gameloop := &g.gameloop

	// // BGR
	src: rl.Rectangle = {
		0,
		0,
		f32(g.textures[.BACKGROUND].width),
		f32(g.textures[.BACKGROUND].height),
	}
	dst: rl.Rectangle = {0, 0, f32(rl.GetRenderWidth()), f32(rl.GetRenderHeight())}
	rl.DrawTexturePro(textures[.BACKGROUND], src, dst, rl.Vector2{0, 0}, 0.0, rl.WHITE)

	//rl.BeginMode2D(game_camera())


	// // Hole plain
	origin: rl.Vector2

	almost_black: rl.Color = {10, 10, 10, 255}
	for &hole in g.holeManager.holes {
		rl.DrawCircle(i32(hole.x), i32(hole.y), hole.size * 0.2, rl.BLACK)
		//rl.DrawCircleLines(i32(hole.x), i32(hole.y), hole.size * hole.reach_radius, rl.BLUE)
	}

	// object plain
	cloud_src: rl.Rectangle = {0, 0, f32(textures[.CLOUD].width), f32(textures[.CLOUD].height)}
	for i in 0 ..< len(objects) {
		dst = {pos[i].x, pos[i].y, size[i].width * 2, size[i].height * 2}
		origin = {size[i].width, size[i].height}
		rl.DrawTexturePro(textures[.CLOUD], cloud_src, dst, origin, 0.0, rl.WHITE)
	}


	//hole glow
	src_bot: rl.Rectangle : {0, 0, 256, 256}
	src_top: rl.Rectangle : {256, 0, 256, 256}
	dual_texture := g.textures[.DUAL_GLOW]
	max_size := g.holeManager.stats.max_size * g.skills.float[.HOLE_MAX_SIZE]
	inv_max_size := 1 / max_size

	max_intensity := max_size / 200
	rl.BeginBlendMode(rl.BlendMode.ADDITIVE)
	for &hole in g.holeManager.holes {
		dst = {hole.x, hole.y, hole.size * 2, hole.size * 2}
		origin = {hole.size, hole.size}

		intensity := math.min(hole.size * inv_max_size, max_intensity)
		lowest: f32 = 10
		col_val: u8 = u8(lowest + f32(255 - lowest) * intensity)
		col: rl.Color = {col_val, col_val, col_val, 255}

		rl.DrawTexturePro(dual_texture, src_bot, dst, origin, 0.0, col)
		rl.DrawTexturePro(dual_texture, src_top, dst, origin, 0.0, col)
	}

	// //object glow
	for i in 0 ..< len(objects) {
		dst = {pos[i].x, pos[i].y, size[i].width * 2, size[i].height * 2}
		origin = {size[i].width, size[i].height}

		//randRotate := rand.float32_range(0, 360)
		//rl.DrawTexturePro(textures[.CLOUD], cloud_src, dst, origin, 0, rl.WHITE)
		rl.DrawTexturePro(dual_texture, src_bot, dst, origin, 0.0, rl.BLUE)
		//rl.DrawTexturePro(dual_texture, src_top, dst, origin, 0.0, rl.WHITE)
	}
	rl.EndBlendMode()

	// rl.EndMode2D()

	//rl.BeginMode2D(ui_camera())

	resource_draw(&g.resources)

	button_draw(slice.enumerated_array(&g.gameloop.buttons))
	button_draw_active(
		gameloop.actives.buttons,
		gameloop.actives.cooldowns,
		gameloop.actives.enabled,
	)

	FONT_SIZE :: 20
	manager := &g.holeManager
	holes_text := fmt.ctprintf("Holes: %i/%i", manager.current, g.skills.int[.HOLE_MAX_HOLE_COUNT])
	holes_text_size := rl.MeasureTextEx(rl.GetFontDefault(), holes_text, FONT_SIZE, 1.0)
	x := i32(f32(rl.GetRenderWidth()) / 2 - holes_text_size.x / 2)
	y := rl.GetRenderHeight() - i32(holes_text_size.y * 2)
	rl.DrawText(holes_text, x, y, FONT_SIZE, rl.RAYWHITE)

	frame_col: rl.Color = {130, 130, 130, 100}
	rl.DrawRectangle(2, 2, 200, 150, frame_col)

	rl.DrawText(
		fmt.ctprintf(
			"fps: %i\nObjects: %i\nHoles:%i\ninput: %.4fms\nupdate: %.4fms\nrender: %.4fms",
			rl.GetFPS(),
			len(objects),
			len(g.holeManager.holes),
			input_time,
			update_time,
			render_time,
		),
		5,
		5,
		20,
		rl.BLACK,
	)

	//rl.EndMode2D()
}

