package game

import "base:intrinsics"
import c "components"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"
//debug
import "core:fmt"

HoleManager :: struct {
	holes:   [dynamic]Hole,
	stats:   HoleStats,
	max:     int,
	current: int,
}

HoleStats :: struct {
	evaporationForce: f32,
	growth_rate:      f64,
	max_size:         f32,
}

Hole :: struct {
	using pos:    c.Position,
	size:         f32,
	using phys:   c.Physic,
	reach_radius: f32,
}

hole_create_default :: proc() -> Hole {
	mousePos := rl.GetMousePosition()
	pos := rl.GetScreenToWorld2D(mousePos, game_camera())

	return {x = pos.x, y = pos.y, size = 80, reach_radius = 4.0, mass = 100000.0}
}

hole_create_random :: proc() -> Hole {
	factor := rand.float32_range(1, 10)

	return {
		x = rand.float32_range(0, f32(rl.GetRenderWidth())),
		y = rand.float32_range(0, f32(rl.GetRenderHeight())),
		size = 10 * factor,
		reach_radius = 4.0,
		mass = 10000.0 * factor,
	}
}

hole_remove :: proc(manager: ^HoleManager, index: int) {
	unordered_remove(&manager.holes, index)
	manager.current -= 1
}

hole_input_size :: proc(manager: ^HoleManager) {
	if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) && manager.current < manager.max {
		append(&manager.holes, hole_create_default())
		manager.current += 1
	}

}

hole_evaporate :: proc(hole: ^Hole, stats: ^HoleStats, dt: f32) -> bool {
	lambda: f32 : 0.33

	p: f32 = 5
	s: f32 = lambda + (1.0 / hole.size) * p
	hole.size *= math.exp(-s * dt)

	is_evaporated := false

	if hole.size < 2.0 {
		is_evaporated = true
	}

	return is_evaporated
}

hole_attract_objects :: proc(
	hole: ^Hole,
	stats: ^HoleStats,
	positions: ^#soa[dynamic]c.Position,
	physics: ^#soa[dynamic]c.Physic,
	sizes: ^#soa[dynamic]c.Size,
) #no_bounds_check {
	damp: f32 : 50.0


	holeOuterRadius := hole.size * hole.reach_radius

	px := positions.x
	py := positions.y
	sw := sizes.width
	sh := sizes.height
	ax := physics.ax
	ay := physics.ay
	mass := physics.mass

	length := len(positions^)

	toRemove := make([dynamic]int, 0, context.temp_allocator)

	for i in 0 ..< length {

		if !intersects(f32(hole.x), f32(hole.y), holeOuterRadius, px[i], py[i], sw[i], sh[i]) {
			continue
		}

		holeInnerRadius := hole.size / 2
		if intersects(f32(hole.x), f32(hole.y), holeInnerRadius, px[i], py[i], sw[i], sh[i]) {
			append(&toRemove, i)
			continue
		}

		dx := f32(hole.x) - px[i]
		dy := f32(hole.y) - py[i]

		d2 := dx * dx + dy * dy

		denom := d2 + damp
		strength := hole.mass / denom


		ax[i] += (dx * strength) / mass[i]
		ay[i] += (dy * strength) / mass[i]
	}


	size_growth: f64 = 0.0
	mass_growth: f64 = 0.0

	#reverse for i in toRemove {
		size_growth += (f64(sw[i]) + f64(sh[i]) / 2.0) * stats.growth_rate
		mass_growth += f64(mass[i])
		//this should not be done from hole, hole should only report what indexes shoudl be removed
		objects_remove(i, positions, physics, sizes)
	}

	if mass_growth > 0 {
		hole.size += f32(size_growth)
		hole.mass += f32(mass_growth)

		hole.size = math.min(hole.size, stats.max_size)
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

	mass_factor: f32 = 0.00001
	other.ax += (dx * strength) / (other.mass * mass_factor)
	other.ay += (dy * strength) / (other.mass * mass_factor)

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

hole_eat :: proc(hole: ^Hole, other: ^Hole, stats: ^HoleStats) {
	hole.mass += other.mass / 4
	hole.size += other.size / 4
	hole.size = math.min(hole.size, stats.max_size)
}
