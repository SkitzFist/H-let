package game

import c "components"
import "core:math"
import rl "vendor:raylib"

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
	x, y:         i32,
	size:         f32,
	reach_radius: f32,
	mass:         f32,
}

hole_create_default :: proc() -> Hole {
	mousePos := rl.GetMousePosition()
	pos := rl.GetScreenToWorld2D(mousePos, game_camera())

	return {x = i32(pos.x), y = i32(pos.y), size = 40, reach_radius = 4.0, mass = 100000.0}
}

hole_input_size :: proc(manager: ^HoleManager) {
	if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) && manager.current < manager.max {
		append(&manager.holes, hole_create_default())
		manager.current += 1
	}

}

hole_evaporate :: proc(hole: ^Hole, stats: ^HoleStats, dt: f32) -> bool {
	sizeFactor := 1 / hole.size
	hole.size -= stats.evaporationForce * dt * sizeFactor

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
	damp: f32 : 100.0


	holeOuterRadius := hole.size * hole.reach_radius
	size2 := hole.size * hole.size

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

		rx := dx * holeOuterRadius
		ry := dy * holeOuterRadius

		denom := d2 + damp
		inv_denom := 1.0 / denom
		strength := hole.mass * inv_denom


		ax[i] += (dx * strength) / mass[i]
		ay[i] += (dy * strength) / mass[i]
	}


	size_growth: f64 = 0.0
	mass_growth: f64 = 0.0

	for i in toRemove {
		size_growth += f64(mass[i]) * stats.growth_rate
		mass_growth += f64(mass[i])
		//this should not be done from hole, hole should only report what indexes shoudl be removed
		objects_remove(i, positions, physics, sizes)
	}

	if mass_growth > 0 {
		hole.size += f32(size_growth)
		hole.mass += f32(mass_growth)
	}
}
