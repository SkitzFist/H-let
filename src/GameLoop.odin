package game
import "core:fmt"
import rl "vendor:raylib"

input :: proc() {
	if rl.IsKeyPressed(.ESCAPE) {
		g.run = false
		return
	}

	hole_input_size(&g.holeManager)
}

update :: proc() {
	dt := rl.GetFrameTime()

	for &hole in g.holeManager.holes {
		hole_update_size(&hole, dt)
		hole_attract_objects(&hole, &g.positions, &g.physics, &g.sizes)
	}

	objects_apply_forces(&g.positions, &g.physics, dt)

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
	rl.DrawTexturePro(textures[.BACKGROUND], src, dst, rl.Vector2{0, 0}, 0.0, rl.WHITE)

	rl.BeginMode2D(game_camera())

	// Hole
	for &hole in g.holeManager.holes {
		rl.DrawCircle(hole.x, hole.y, hole.size, rl.BLACK)
		rl.DrawCircleLines(hole.x, hole.y, hole.size * hole.reach_radius, rl.BLUE)
	}


	// objects
	positions := &g.positions
	sizes := &g.sizes
	px := positions.x
	py := positions.y
	sw := sizes.width
	sh := sizes.height

	for i in 0 ..< len(positions^) {
		texture := g.obj_texture[i]

		src = {0, 0, f32(g.textures[texture].width), f32(g.textures[texture].height)}
		dst = {px[i], py[i], sw[i], sh[i]}
		rl.DrawTexturePro(g.textures[texture], src, dst, rl.Vector2{0, 0}, 0.0, rl.WHITE)
	}

	rl.EndMode2D()

	//rl.BeginMode2D(ui_camera())

	rl.DrawText(
		fmt.ctprintf("fps: %i\nObjects: %i", rl.GetFPS(), len(positions^)),
		5,
		5,
		8,
		rl.WHITE,
	)

	//rl.EndMode2D()
}
