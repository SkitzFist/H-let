package game
import "core:fmt"
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
}

durr: f32 = 0.1
curr: f32 = 0.0
update :: proc() {
	dt := rl.GetFrameTime()


	toRemove := make([dynamic]bool, len(g.holeManager.holes), context.temp_allocator)

	for &hole, i in g.holeManager.holes {
		if toRemove[i] {
			continue
		}

		if hole_evaporate(&hole, &g.holeManager.stats, dt) {
			toRemove[i] = true
		}
		hole_attract_objects(&hole, &g.holeManager.stats, &g.positions, &g.physics, &g.sizes)

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

	objects_apply_forces(&g.positions, &g.physics, dt)

	curr += dt

	if curr >= durr {
		//create an object:
		pos: components.Position = {
			x = rand.float32_range(0, f32(rl.GetRenderWidth())),
			y = rand.float32_range(0, f32(rl.GetRenderHeight())),
		}
		phys: components.Physic = {
			mass = rand.float32_range(10, 50),
		}
		size: components.Size = {
			width  = f32(g.textures[.SQUARE].width),
			height = f32(g.textures[.SQUARE].height),
		}
		objects_add(&g.positions, pos, &g.physics, phys, &g.sizes, size, &g.obj_texture, .SQUARE)

		curr = 0
	}
}

draw :: proc() {
	textures := &g.textures

	// BGR
	src: rl.Rectangle = {
		0,
		0,
		f32(g.textures[.BACKGROUND].width),
		f32(g.textures[.BACKGROUND].height),
	}
	dst: rl.Rectangle = {0, 0, f32(rl.GetRenderWidth()), f32(rl.GetRenderHeight())}

	//rl.DrawTexturePro(textures[.BACKGROUND], src, dst, rl.Vector2{0, 0}, 0.0, rl.WHITE)

	rl.BeginMode2D(game_camera())

	rl.BeginBlendMode(.ADDITIVE)
	// Hole
	src = {0, 0, f32(g.textures[.GLOW_BOT].width), f32(g.textures[.GLOW_BOT].height)}
	origin: rl.Vector2 = {
		f32(g.textures[.GLOW_BOT].width) / 2,
		f32(g.textures[.GLOW_BOT].height) / 2,
	}

	for &hole in g.holeManager.holes {
		rl.DrawCircle(i32(hole.x), i32(hole.y), hole.size, {0, 0, 0, 180})
		dst = {hole.x, hole.y, hole.size, hole.size}
		origin = {hole.size / 2, hole.size / 2}
		rl.DrawTexturePro(g.textures[.GLOW_BOT], src, dst, origin, 0.0, rl.WHITE)
		rl.DrawTexturePro(g.textures[.GLOW_BOT], src, dst, origin, 0.0, rl.WHITE)
		rl.DrawCircleLines(i32(hole.x), i32(hole.y), hole.size * hole.reach_radius, rl.BLUE)
	}


	// objects
	positions := &g.positions
	sizes := &g.sizes
	px := positions.x
	py := positions.y
	sw := sizes.width
	sh := sizes.height

	src = {0, 0, f32(g.textures[.GLOW_BOT].width), f32(g.textures[.GLOW_BOT].height)}

	col: rl.Color = {255, 255, 180, 255}

	for i in 0 ..< len(positions^) {
		texture := g.obj_texture[i]
		dst = {px[i], py[i], sw[i], sh[i]}
		origin = {sw[i] / 2, sh[i] / 2}

		rl.DrawTexturePro(g.textures[.GLOW_BOT], src, dst, origin, 0.0, rl.BLUE)
		rl.DrawTexturePro(g.textures[.GLOW_TOP], src, dst, origin, 0.0, rl.WHITE)
	}
	rl.EndBlendMode()

	rl.EndMode2D()

	//rl.BeginMode2D(ui_camera())

	rl.DrawText(
		fmt.ctprintf(
			"fps: %i\nObjects: %i\nHoles:%i",
			rl.GetFPS(),
			len(positions^),
			len(g.holeManager.holes),
		),
		5,
		5,
		8,
		rl.WHITE,
	)

	//rl.EndMode2D()
}
