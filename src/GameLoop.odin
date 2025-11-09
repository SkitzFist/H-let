package game
import "core:fmt"
import "core:math/rand"

import rl "vendor:raylib"

input :: proc() {
	if rl.IsKeyPressed(.ESCAPE) {
		g.run = false
		return
	}

	hole_input_size(&g.ecs, &g.holeManager)
}

//tmp stuff
durr: f32 = 0.5
curr: f32 = 0.0
update :: proc() {
	dt := rl.GetFrameTime()

	c := &g.ecs.components

	// evaporate

	// attract
	attract(&g.ecs, &c.attractors, &c.positions, &c.sizes, &c.physics)

	// apply forces
	apply_forces(&c.positions, &c.physics, dt)

	// collision

	curr += dt
	if curr >= durr {
		//create an object:
		pos: Position = {
			x = rand.float32_range(0, f32(rl.GetRenderWidth())),
			y = rand.float32_range(0, f32(rl.GetRenderHeight())),
		}
		phys: Physic = {
			mass = rand.float32_range(10, 50),
		}
		size: Size = {
			width  = f32(g.textureBank[.SQUARE].width),
			height = f32(g.textureBank[.SQUARE].height),
		}


		curr = 0
	}
}

draw :: proc() {
	textures := &g.textureBank
	c := &g.ecs.components

	// BGR
	src: rl.Rectangle = {
		0,
		0,
		f32(g.textureBank[.BACKGROUND].width),
		f32(g.textureBank[.BACKGROUND].height),
	}
	dst: rl.Rectangle = {0, 0, f32(rl.GetRenderWidth()), f32(rl.GetRenderHeight())}
	rl.DrawTexturePro(textures[.BACKGROUND], src, dst, rl.Vector2{0, 0}, 0.0, rl.WHITE)

	rl.BeginMode2D(game_camera())

	draw_single_texture(g.textureBank, &c.singleTextures, &c.positions, &c.sizes)
	draw_attract_radius(&g.ecs, &c.attractors, &c.positions, &c.sizes)


	rl.EndMode2D()

	//rl.BeginMode2D(ui_camera())

	shortcut_ratio: f64 = index_shortcut / (index_shortcut + index_n_shortcut)

	rl.DrawText(
		fmt.ctprintf(
			"fps: %i\nEntities: %i\nHoles:%i\nshortcut ratio:%.3f",
			rl.GetFPS(),
			len(g.ecs.id),
			len(g.ecs.components.attractors),
			shortcut_ratio,
		),
		5,
		5,
		8,
		rl.WHITE,
	)

	//rl.EndMode2D()
}
