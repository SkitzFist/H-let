package game
import "core:fmt"
import "core:math"
import "core:slice"

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

game_loop_on_enter :: proc() {

}

game_loop_on_exit :: proc() {

}

game_loop_input :: proc() {
	gameloop := &g.gameloop
	actives := &gameloop.actives

	if rl.IsKeyPressed(rl.KeyboardKey.T) {
		switch_scene(.SKILL_TREE)
	}

	gameloop.on_button = button_input(slice.enumerated_array(&g.gameloop.buttons))
	if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) && gameloop.on_button != -1 {
		g.gameloop.buttons[ButtonMap(gameloop.on_button)].func()
	}

	active_button_index := actives_input(&gameloop.actives)

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

game_loop_update :: proc(dt: f32) {
	holeManager := &g.holeManager
	holes := &holeManager.holes
	objects := &g.objects
	obj_stats := &g.objectStats
	skills := &g.skills
	resources := &g.resources
	gameloop := &g.gameloop
	tileMap := &g.tileMap

	bench_start("set_tile_index")
	set_tile_index(objects.tile_index, objects.x, objects.y, len(objects))
	bench_end()

	bench_start("build_tile_map")
	build_tile_map(tileMap, objects.tile_index, len(objects))
	bench_end()

	attract(
		holes.x,
		holes.y,
		holes.mass,
		holes.ax,
		holes.ay,
		objects.x,
		objects.y,
		objects.mass,
		objects.ax,
		objects.ay,
		len(holes),
		len(objects),
		2.5,
	)

	// attract_same_simd(objects.x, objects.y, objects.mass, objects.ax, objects.ay, len(objects))

	friction :: 0.1
	bench_start("apply_force")
	apply_force(holes.x, holes.y, holes.ax, holes.ay, holes.vx, holes.vy, len(holes), dt, friction)

	apply_force(
		objects.x,
		objects.y,
		objects.ax,
		objects.ay,
		objects.vx,
		objects.vy,
		len(objects),
		dt,
		friction,
	)
	bench_end()

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

game_loop_render :: proc() #no_bounds_check {
	textures := &g.textures
	objects := &g.objects
	gameloop := &g.gameloop
	holes := &g.holeManager.holes

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
	for i in 0 ..< len(holes) {
		rl.DrawCircle(i32(holes[i].x), i32(holes[i].y), holes[i].size / 2, rl.BLACK)
		// rl.DrawCircleLines(i32(hole.x), i32(hole.y), hole.size * hole.reach_radius, rl.BLUE)
	}

	// object plain
	cloud_src: rl.Rectangle = {0, 0, f32(textures[.CLOUD].width), f32(textures[.CLOUD].height)}
	for i in 0 ..< len(objects) {
		dst = {objects.x[i], objects.y[i], objects.width[i] * 2, objects.height[i] * 2}
		origin = {objects.width[i], objects.height[i]}
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
	for i in 0 ..< len(holes) {
		dst = {
			holes[i].x - holes[i].size,
			holes[i].y - holes[i].size,
			holes[i].size * 4,
			holes[i].size * 4,
		}
		origin = {holes[i].size, holes[i].size}

		intensity := math.min(holes[i].size * inv_max_size, max_intensity)
		lowest: f32 = 10
		col_val: u8 = u8(lowest + f32(255 - lowest) * intensity)
		col: rl.Color = {col_val, col_val, col_val, 255}

		rl.DrawTexturePro(dual_texture, src_bot, dst, origin, 0.0, col)
		rl.DrawTexturePro(dual_texture, src_top, dst, origin, 0.0, col)
	}

	// //object glow
	for i in 0 ..< len(objects) {
		dst = {objects.x[i], objects.y[i], objects.width[i] * 2, objects.height[i] * 2}
		origin = {objects.width[i], objects.height[i]}
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
		gameloop.actives.cooldown_reductions,
		gameloop.actives.enabled,
	)


	draw_tile_map()

	bench_draw(2, 60)

	FONT_SIZE :: 20
	manager := &g.holeManager
	holes_text := fmt.ctprintf("Holes: %i/%i", manager.current, g.skills.int[.HOLE_MAX_HOLE_COUNT])
	holes_text_size := rl.MeasureTextEx(rl.GetFontDefault(), holes_text, FONT_SIZE, 1.0)
	x := i32(f32(rl.GetRenderWidth()) / 2 - holes_text_size.x / 2)
	y := rl.GetRenderHeight() - i32(holes_text_size.y * 2)
	rl.DrawText(holes_text, x, y, FONT_SIZE, rl.RAYWHITE)

	frame_col: rl.Color = {130, 130, 130, 100}
	rl.DrawRectangle(2, 2, 200, 50, frame_col)

	rl.DrawText(
		fmt.ctprintf("fps: %i\nObjects: %i", rl.GetFPS(), len(objects)),
		5,
		5,
		20,
		rl.BLACK,
	)

	//rl.EndMode2D()
}

