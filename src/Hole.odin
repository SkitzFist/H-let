package game

import rl "vendor:raylib"

HoleManager :: struct {
	holes:   #soa[dynamic]Hole,
	stats:   HoleStats,
	max:     int,
	current: int,
}

HoleStats :: struct {
	evaporation_rate: f32,
	growth_rate:      f64,
	start_size:       f32,
	max_size:         f32,
}

Hole :: struct {
	x, y, size, ax, ay, vx, vy, mass: f32,
	resources_eaten:                  [ResourceType]int,
}

hole_manager_create_default :: proc() -> HoleManager {
	return {
		holes = make(#soa[dynamic]Hole, 0, 5, context.allocator),
		max = 1,
		current = 0,
		stats = hole_stats_create_default(),
	}
}

//TODO rework stats into skills
hole_stats_create_default :: proc() -> HoleStats {
	return {evaporation_rate = 0.33, growth_rate = 0.25, start_size = 30, max_size = 150}
}

hole_create_default :: proc() {
	mousePos := rl.GetMousePosition()
	pos := rl.GetScreenToWorld2D(mousePos, game_camera())

	stats := &g.holeManager.stats
	skills := &g.skills

	hole: Hole = {
		x    = pos.x,
		y    = pos.y,
		size = stats.start_size * skills.float[.HOLE_START_SIZE],
		mass = f32(skills.int[.HOLE_MASS]),
	}

	append_soa(&g.holeManager.holes, hole)
}

hole_remove :: proc(manager: ^HoleManager, index: int) {
	unordered_remove_soa(&manager.holes, index)
	manager.current -= 1
}

hole_input :: proc(manager: ^HoleManager) {
	//Return early if mousebutton is nott pressed
	if !rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
		return
	}

	mouse_pos := rl.GetMousePosition()
	mouse_pos = rl.GetScreenToWorld2D(mouse_pos, game_camera())

	// Return early if clicking inside another hole
	for i in 0 ..< len(manager.holes) {
		if intersects_point_circle(
			mouse_pos.x,
			mouse_pos.y,
			manager.holes[i].x,
			manager.holes[i].y,
			manager.holes[i].size,
		) {
			return
		}
	}

	if manager.current >= g.skills.int[.HOLE_MAX_HOLE_COUNT] {
		return
	}

	hole_create_default()
	manager.current += 1
}

// TODO implement evaporate and collision
// hole_evaporate :: proc(hole: ^Hole, stats: ^HoleStats, dt: f32) -> bool {
// 	lambda: f32 = stats.evaporation_rate * g.skills.float[.HOLE_EVAPORATION_RATE]

// 	p: f32 = 10
// 	s: f32 = lambda + (1.0 / hole.size) * p
// 	mass_factor := hole.mass / (f32(g.skills.int[.HOLE_MASS]) * 3)
// 	change := (-s * dt) * mass_factor

// 	hole.size *= math.exp(change)

// 	is_evaporated := false

// 	if hole.size < 5.0 {
// 		is_evaporated = true
// 	}

// 	return is_evaporated
// }

// hole_eat_hole :: proc(hole: ^Hole, other: ^Hole, stats: ^HoleStats) {
// 	hole.mass += other.mass
// 	hole.size += other.size
// 	max_size := stats.max_size * g.skills.float[.HOLE_MAX_SIZE]
// 	hole.size = math.min(hole.size, max_size)
// 	hole.resources_eaten += other.resources_eaten
// 	other.resources_eaten = {}
// 	hole.resources_eaten[.HOLE] += 1
// }

