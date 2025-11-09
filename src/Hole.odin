package game

import rl "vendor:raylib"

HoleManager :: struct {
	stats:   HoleStats,
	max:     int,
	current: int,
}

HoleStats :: struct {
	evaporation_force: f32,
	growth_rate:       f64,
}

Hole :: struct {
	reach_radius: f32,
}

hole_create_default :: proc(ecs: ^Ecs) {

	id, err := create_entity(ecs)

	mousePos := rl.GetMousePosition()
	mousePos = rl.GetScreenToWorld2D(mousePos, game_camera())

	pos: Position = {
		x  = mousePos.x,
		y  = mousePos.y,
		id = id,
	}
	add_component(ecs, pos, id)

	phys: Physic = {
		ax         = 0,
		ay         = 0,
		vx         = 0,
		vy         = 0,
		mass       = 100000.0,
		properties = {},
		id         = id,
	}
	add_component(ecs, phys, id)

	SIZE :: 80
	size: Size = {
		width  = SIZE,
		height = SIZE,
		id     = id,
	}
	add_component(ecs, size, id)

	attractor: Attractor = {
		damp                = 1,
		reach_radius_factor = 4,
		id                  = id,
	}
	add_component(ecs, attractor, id)

	singleTexture: SingleTexture = {
		type = .HOLE,
		id   = id,
	}
	add_component(ecs, singleTexture, id)
}

hole_input_size :: proc(ecs: ^Ecs, manager: ^HoleManager) {
	if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) && manager.current < manager.max {
		hole_create_default(ecs)
		manager.current += 1
	}

}

hole_evaporate :: proc(
	sizes: ^#soa[dynamic]Size,
	physics: ^#soa[dynamic]Physic,
	index: int,
	stats: ^HoleStats,
	dt: f32,
) -> bool {
	sizeFactor := 1 / sizes[index].width
	change := stats.evaporation_force * dt * sizeFactor
	sizes[index].width -= change
	sizes[index].height -= change

	massFactor: f32 = 1.0
	physics[index].mass -= stats.evaporation_force * dt * massFactor

	if sizes[index].width < 2.0 {
		return true
	}

	return false
}
