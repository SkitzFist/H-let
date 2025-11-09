package game

import "core:crypto/hash"
import "core:math"
import "core:sync/chan"

import rl "vendor:raylib"

import c "components"

HoleManager :: struct {
	holes:   [dynamic]Hole,
	stats:   HoleStats,
	max:     int,
	current: int,
}

HoleStats :: struct {
	evaporationForce: f32,
	growth_rate:      f64,
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

	return {x = pos.x, y = pos.y, size = 40, reach_radius = 4.0, mass = 100000.0}
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

	hole.size -= ((1 / hole.size) * stats.evaporationForce * dt)

	hole.mass -= ((1 / hole.mass) * stats.evaporationForce * dt)


	if hole.size < 2.0 {
		return true
	}

	return false
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

		holeInnerRadius := hole.size - (sw[i] * 2)
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
	}
}

hole_attract_hole :: proc(hole: ^Hole, other: ^Hole) -> (isColliding: bool) {
	damp: f32 : 2.0
	holeOuterRadius := hole.size * hole.reach_radius

	if !intersects(hole.x, hole.y, holeOuterRadius, other.x, other.y, other.size) {
		return false
	}

	if intersects(hole.x, hole.y, hole.size, other.x, other.y, other.size) {
		return true
	}


	dx := hole.x - other.x
	dy := hole.y - other.y

	d := math.sqrt(dx * dx + dy * dy)

	denom := d
	strength := hole.mass / denom

	other.ax += (dx * strength) / other.mass
	other.ay += (dy * strength) / other.mass

	return false
}


hole_apply_force :: proc(hole: ^Hole, dt: f32) {
	hole.vx += hole.ax * dt
	hole.vy += hole.ay * dt

	hole.ax = 0
	hole.ay = 0

	hole.x += hole.vx * dt
	hole.y += hole.vy * dt
}
