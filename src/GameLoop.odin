package game
import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:time"

import rl "vendor:raylib"

import "components"

input :: proc() {
	if rl.IsKeyPressed(.ESCAPE) {
		g.run = false
		return
	}

	hole_input_size(&g.holeManager)

	if rl.IsKeyPressed(rl.KeyboardKey.PERIOD) {
		for i in 0 ..< 10_000 {
			objects_add_random()
		}
	}
}

durr: f32 = 0.1
curr: f32 = 0.0
update :: proc(dt: f32) {
	holeManager := &g.holeManager
	objects := &g.objects

	toRemove := make([dynamic]bool, len(g.holeManager.holes), context.temp_allocator)
	obj_to_remove := make([dynamic]int, 0, context.temp_allocator)
	for &hole, i in holeManager.holes {
		if toRemove[i] {
			continue
		}

		if hole_evaporate(&hole, &holeManager.stats, dt) {
			toRemove[i] = true
		}

		hole_attract_objects(
			&hole,
			&holeManager.stats,
			&objects.positions,
			&objects.physics,
			&objects.sizes,
			&obj_to_remove,
		)

		#reverse for obj in obj_to_remove {
			resource_gain(
				&g.resources,
				objects.resource_gains[obj].type,
				objects.resource_gains[obj].value,
			)

			objects_remove(obj)
		}

		clear_dynamic_array(&obj_to_remove)

		for &other, oi in g.holeManager.holes {
			if i == oi || toRemove[oi] {
				continue
			}

			if hole_attract_hole(&hole, &other) {
				if hole.size > other.size {
					toRemove[oi] = true
					hole_eat(&hole, &other, &g.holeManager.stats)

				} else {
					toRemove[i] = true
					hole_eat(&other, &hole, &g.holeManager.stats)
					continue
				}
			}
		}

		hole_apply_force(&hole, dt)
	}

	#reverse for shouldRemove, i in toRemove {
		if shouldRemove {
			unordered_remove(&g.holeManager.holes, i)
			g.holeManager.current -= 1
		}
	}

	objects_apply_forces(&objects.positions, &objects.physics, dt)

	curr += dt

	if curr >= durr {
		objects_add_random()
		curr = 0
	}
}

draw :: proc() #no_bounds_check {
	textures := &g.textures
	objects := &g.objects

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


	// // Hole
	origin: rl.Vector2

	almost_black: rl.Color = {10, 10, 10, 255}
	for &hole in g.holeManager.holes {
		rl.DrawCircle(i32(hole.x), i32(hole.y), hole.size * 0.2, rl.BLACK)
		//rl.DrawCircleLines(i32(hole.x), i32(hole.y), hole.size * hole.reach_radius, rl.BLUE)
	}

	src_bot: rl.Rectangle : {0, 0, 256, 256}
	src_top: rl.Rectangle : {256, 0, 256, 256}
	dual_texture := g.textures[.DUAL_GLOW]
	rl.BeginBlendMode(rl.BlendMode.ADDITIVE)
	for &hole in g.holeManager.holes {
		dst = {hole.x, hole.y, hole.size * 2, hole.size * 2}
		origin = {hole.size, hole.size}
		intensity := hole.size / g.holeManager.stats.max_size
		lowest: f32 = 10
		col_val: u8 = u8(lowest + f32(255 - lowest) * intensity)
		col: rl.Color = {col_val, col_val, col_val, 255}


		rl.DrawTexturePro(dual_texture, src_bot, dst, origin, 0.0, col)
		rl.DrawTexturePro(dual_texture, src_top, dst, origin, 0.0, col)
	}

	// objects
	positions := &objects.positions
	sizes := &objects.sizes
	px := positions.x
	py := positions.y
	sw := sizes.width
	sh := sizes.height

	for i in 0 ..< len(positions^) {
		dst = {px[i], py[i], sw[i] * 2, sh[i] * 2}
		origin = {sw[i], sh[i]}

		rl.DrawTexturePro(dual_texture, src_bot, dst, origin, 0.0, rl.BLUE)
		//rl.DrawTexturePro(dual_texture, src_top, dst, origin, 0.0, rl.WHITE)
	}
	rl.EndBlendMode()

	// rl.EndMode2D()

	//rl.BeginMode2D(ui_camera())

	resource_draw(&g.resources)

	frame_col: rl.Color = {130, 130, 130, 100}
	rl.DrawRectangle(2, 2, 200, 150, frame_col)

	rl.DrawText(
		fmt.ctprintf(
			"fps: %i\nObjects: %i\nHoles:%i\ninput: %.4fms\nupdate: %.4fms\nrender: %.4fms",
			rl.GetFPS(),
			len(positions^),
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
