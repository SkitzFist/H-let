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
}

Hole :: struct {
	using pos:       Position,
	size:            f32,
	using phys:      Physic,
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
	return {evaporation_rate = 0.33, growth_rate = 0.25, start_size = 30, max_size = 150}
}

hole_create_default :: proc() -> Hole {
	mousePos := rl.GetMousePosition()
	pos := rl.GetScreenToWorld2D(mousePos, game_camera())

	stats := &g.holeManager.stats
	skills := &g.skills

	start_size := stats.start_size * skills.float[.HOLE_START_SIZE]
	mass: f32 = f32(skills.int[.HOLE_MASS])

	return {x = pos.x, y = pos.y, size = start_size, mass = mass}
}

hole_remove :: proc(manager: ^HoleManager, index: int) {
	unordered_remove(&manager.holes, index)
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
	for &hole in manager.holes {
		if intersects_point_circle(mouse_pos.x, mouse_pos.y, hole.pos.x, hole.pos.y, hole.size) {
			return
		}
	}

	if manager.current >= g.skills.int[.HOLE_MAX_HOLE_COUNT] {
		return
	}

	append(&manager.holes, hole_create_default())
	manager.current += 1
}

hole_evaporate :: proc(hole: ^Hole, stats: ^HoleStats, dt: f32) -> bool {
	lambda: f32 = stats.evaporation_rate * g.skills.float[.HOLE_EVAPORATION_RATE]

	p: f32 = 10
	s: f32 = lambda + (1.0 / hole.size) * p
	mass_factor := hole.mass / (f32(g.skills.int[.HOLE_MASS]) * 3)
	change := (-s * dt) * mass_factor

	hole.size *= math.exp(change)

	is_evaporated := false

	if hole.size < 5.0 {
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

	pos := &objects.pos
	size := &objects.size
	phys := &objects.phys

	length := len(objects)

	skills := &g.skills
	growth_rate := stats.growth_rate * f64(skills.float[.HOLE_GROWTH_RATE])
	max_size := stats.max_size * skills.float[.HOLE_MAX_SIZE]

	for i in 0 ..< length {
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

		gForce := (hole.mass * phys[i].mass) / d2
		strength := gForce / phys[i].mass

		phys[i].ax += (dx * strength)
		phys[i].ay += (dy * strength)

		strength = gForce / hole.mass
		hole.ax += (-dx * strength)
		hole.ay += (-dy * strength)
	}

	//TODO move collision resolution out of this
	size_growth: f64 = 0.0
	mass_growth: f64 = 0.0

	for i in toRemove {
		size_growth += ((f64(size[i].width) + f64(size[i].height)) / 2.0) * growth_rate
		mass_growth += f64(phys[i].mass)
	}

	if mass_growth > 0 {
		max_growth_per_frame := hole.size * 0.025
		hole.size += math.min(max_growth_per_frame, f32(size_growth))
		hole.mass += f32(mass_growth)
		hole.size = math.min(hole.size, max_size)
	}
}

hole_attract_hole :: proc(hole: ^Hole, other: ^Hole) -> (isColliding: bool) {
	eat_radius := math.min(hole.size, other.size) / 5
	if intersects(hole.x, hole.y, eat_radius, other.x, other.y, eat_radius) {
		return true
	}

	dx := hole.x - other.x
	dy := hole.y - other.y
	dist := dx * dx + dy * dy

	G :: 5.0
	gForce := G * ((hole.mass * other.mass) / dist)
	strength := gForce / other.mass

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
	hole.mass += other.mass
	hole.size += other.size
	max_size := stats.max_size * g.skills.float[.HOLE_MAX_SIZE]
	hole.size = math.min(hole.size, max_size)
	hole.resources_eaten += other.resources_eaten
	other.resources_eaten = {}
	hole.resources_eaten[.HOLE] += 1
}

