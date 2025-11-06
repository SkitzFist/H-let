package game
import "core:fmt"
import "core:math/rand"
import rl "vendor:raylib"

input :: proc() {
	if rl.IsKeyPressed(.ESCAPE) {
		g.run = false
		return
	}

	hole_input_size(&g.hole)
}

update :: proc() {
	dt := rl.GetFrameTime()

	hole_update_size(&g.hole, dt)
	hole_attract_objects(&g.hole, &g.objects, g.toRemove[:])

	objects_apply_forces(&g.objects, dt)

}

draw :: proc() {
	hole := &g.hole
	objects := &g.objects
	textures := &g.textures

	rl.BeginDrawing()
	rl.ClearBackground(rl.GRAY)

	src: rl.Rectangle = {
		0,
		0,
		f32(g.textures[.BACKGROUND].width),
		f32(g.textures[.BACKGROUND].height),
	}
	dst: rl.Rectangle = {0, 0, f32(rl.GetRenderWidth()), f32(rl.GetRenderHeight())}
	rl.DrawTexturePro(textures[.BACKGROUND], src, dst, rl.Vector2{0, 0}, 0.0, rl.WHITE)

	rl.BeginMode2D(game_camera())
	rl.DrawCircle(hole.x, hole.y, hole.size, rl.BLACK)

	rl.DrawCircleLines(hole.x, hole.y, hole.size * hole.reach_radius, rl.BLUE)

	for i in 0 ..< objects.length {
		rl.DrawTexture(objects.texture, i32(objects.x[i]), i32(objects.y[i]), rl.WHITE)
	}

	rl.EndMode2D()

	//rl.BeginMode2D(ui_camera())

	rl.DrawText(
		fmt.ctprintf("fps: %i\nObjects: %i", rl.GetFPS(), objects.length),
		5,
		5,
		8,
		rl.WHITE,
	)

	//rl.EndMode2D()

	rl.EndDrawing()
}
