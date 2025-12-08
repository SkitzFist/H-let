package game

import "core:math"
import rl "vendor:raylib"

// TODO make holes soa
HoleManager :: struct {
	holes:   [dynamic]Hole,
	stats:   HoleStats,
	max:     int,
	current: int,
}

HoleStats :: struct {
	evaporation_rate: f32,
	growth_rate:      f64,
	start_size:       f32,
	max_size:         f32,
	reach_radius:     f32,
}

Hole :: struct {
	using pos:       Position,
	size:            f32,
	using phys:      Physic,
	reach_radius:    f32,
	resources_eaten: [ResourceType]int,
}

hole_manager_create_default :: proc() -> HoleManager {
	return {
		holes = make([dynamic]Hole, 0, 1000, context.allocator),
		max = 1,
		current = 0,
		stats = hole_stats_create_default(),
	}
}

hole_stats_create_default :: proc() -> HoleStats {
	return {
		evaporation_rate = 0.33,
		growth_rate = 0.25,
		start_size = 40,
		max_size = 1000,
		reach_radius = 2,
	}
}

hole_create_default :: proc() -> Hole {
	mousePos := rl.GetMousePosition()
	pos := rl.GetScreenToWorld2D(mousePos, game_camera())

	stats := &g.holeManager.stats
	skills := &g.skills

	start_size := stats.start_size * skills.float[.HOLE_START_SIZE]
	reach_radius := stats.reach_radius * skills.float[.HOLE_REACH_RADIUS]

	return {x = pos.x, y = pos.y, size = start_size, reach_radius = reach_radius, mass = 100000.0}
}

hole_remove :: proc(manager: ^HoleManager, index: int) {
	unordered_remove(&manager.holes, index)
	manager.current -= 1
}

hole_input :: proc(manager: ^HoleManager) {
	can_spawn_hole :=
		rl.IsMouseButtonPressed(rl.MouseButton.LEFT) &&
		manager.current < g.skills.int[.HOLE_MAX_HOLE_COUNT]

	if can_spawn_hole {
		append(&manager.holes, hole_create_default())
		manager.current += 1
	}

}

hole_evaporate :: proc(hole: ^Hole, stats: ^HoleStats, dt: f32) -> bool {
	lambda: f32 = stats.evaporation_rate * g.skills.float[.HOLE_EVAPORATION_RATE]

	p: f32 = 10
	s: f32 = lambda + (1.0 / hole.size) * p
	change := math.exp(-s * dt)

	hole.size *= change

	is_evaporated := false

	if hole.size < 2.0 {
		is_evaporated = true
	}

	return is_evaporated
}

hole_attract_objects :: proc(
	hole: ^Hole,
	stats: ^HoleStats,
	objects: ^#soa[dynamic]Object,
	toRemove: ^[dynamic]int,
) #no_bounds_check {
	damp: f32 : 50


	holeOuterRadius := hole.size * hole.reach_radius

	pos := &objects.pos
	size := &objects.size
	phys := &objects.phys

	length := len(objects)

	skills := &g.skills
	growth_rate := stats.growth_rate * f64(skills.float[.HOLE_GROWTH_RATE])
	max_size := stats.max_size * skills.float[.HOLE_MAX_SIZE]

	for i in 0 ..< length {

		if !intersects(
			f32(hole.x),
			f32(hole.y),
			holeOuterRadius,
			pos[i].x,
			pos[i].y,
			size[i].width,
			size[i].height,
		) {
			continue
		}

		holeInnerRadius := hole.size * 0.2
		if intersects(
			f32(hole.x),
			f32(hole.y),
			holeInnerRadius,
			pos[i].x,
			pos[i].y,
			size[i].width,
			size[i].height,
		) {
			append(toRemove, i)
			continue
		}

		dx := f32(hole.x) - pos[i].x
		dy := f32(hole.y) - pos[i].y

		d2 := dx * dx + dy * dy

		denom := d2 + damp
		strength := hole.mass / denom


		phys[i].ax += (dx * strength) / phys[i].mass
		phys[i].ay += (dy * strength) / phys[i].mass
	}


	size_growth: f64 = 0.0
	mass_growth: f64 = 0.0

	for i in toRemove {
		size_growth += ((f64(size[i].width) + f64(size[i].height)) / 2.0) * growth_rate
		mass_growth += f64(phys[i].mass)
		hole.resources_eaten[.DUST] += 1
	}

	if mass_growth > 0 {
		max_growth_per_frame := hole.size * 0.025
		hole.size += math.min(max_growth_per_frame, f32(size_growth))
		hole.mass += f32(mass_growth)
		hole.size = math.min(hole.size, max_size)
	}
}

hole_attract_hole :: proc(hole: ^Hole, other: ^Hole) -> (isColliding: bool) {
	damp: f32 : 1000.0
	holeOuterRadius := hole.size * hole.reach_radius

	if !intersects(hole.x, hole.y, holeOuterRadius, other.x, other.y, other.size) {
		return false
	}

	eat_radius := math.min(hole.size, other.size) / 100
	if intersects(hole.x, hole.y, eat_radius, other.x, other.y, eat_radius) {
		return true
	}

	dx := hole.x - other.x
	dy := hole.y - other.y

	dist := dx * dx + dy * dy

	denom := dist + damp
	strength := hole.mass / denom

	other.ax += (dx * strength)
	other.ay += (dy * strength)
	return false
}


hole_apply_force :: proc(hole: ^Hole, dt: f32) {

	lambda: f32 : 0.5

	hole.vx += hole.ax * dt
	hole.vy += hole.ay * dt

	hole.ax = 0
	hole.ay = 0

	hole.vx *= math.exp(-lambda * dt)
	hole.vy *= math.exp(-lambda * dt)

	hole.x += hole.vx * dt
	hole.y += hole.vy * dt

	if hole.x < 0 {
		hole.x = 0
		hole.vx *= -1
	} else if hole.x > f32(rl.GetRenderWidth()) {
		hole.x = f32(rl.GetRenderWidth())
		hole.vx *= -1
	}

	if hole.y < 0 {
		hole.y = 0
		hole.vy *= -1
	} else if hole.y > f32(rl.GetRenderHeight()) {
		hole.y = f32(rl.GetRenderHeight())
		hole.vy *= -1
	}
}

hole_eat_hole :: proc(hole: ^Hole, other: ^Hole, stats: ^HoleStats) {
	hole.mass += other.mass / 2
	hole.size += other.size
	max_size := stats.max_size * g.skills.float[.HOLE_MAX_SIZE]
	hole.size = math.min(hole.size, max_size)
	hole.resources_eaten[.HOLE] += 1
}

