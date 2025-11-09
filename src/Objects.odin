package game

import "core:math/rand"
import rl "vendor:raylib"


objects_add_random :: #force_inline proc(ecs: ^Ecs) {
	id, err := create_entity(&g.ecs)

	pos: Position = {
		x  = rand.float32_range(0, f32(rl.GetRenderWidth())),
		y  = rand.float32_range(0, f32(rl.GetRenderHeight())),
		id = id,
	}
	add_component(&g.ecs, pos, id)

	factor := rand.float32_range(1.0, 2.0)

	base_mass: f32 = 10
	phys: Physic = {
		mass       = base_mass * factor,
		properties = {.DENOM},
		id         = id,
	}
	add_component(&g.ecs, phys, id)

	size: Size = {
		width  = f32(g.textureBank[.SQUARE].width) * factor,
		height = f32(g.textureBank[.SQUARE].height) * factor,
		id     = id,
	}
	add_component(&g.ecs, size, id)

	texture: SingleTexture = {
		type = .SQUARE,
		id   = id,
	}
	add_component(&g.ecs, texture, id)
}
