package game

import "core:math"
import rl "vendor:raylib"

Hole :: struct {
	x, y:                  i32,
	size:                  f32,
	base_reach_radius:     f32,
	reach_radius:          f32,
	mass:                  f32,
	max_reach_multiplier:  f32,
	curr_reach_multiplier: f32,
}

hole_input_size :: proc(hole: ^Hole) {
	INC_FACTOR :: 0.05

	if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
		hole.curr_reach_multiplier += INC_FACTOR
	}

	hole.curr_reach_multiplier = math.min(hole.max_reach_multiplier, hole.curr_reach_multiplier)
}

hole_update_size :: proc(hole: ^Hole, dt: f32) {
	DAMP :: 0.1
	if hole.curr_reach_multiplier > 0.0 {
		hole.curr_reach_multiplier -= DAMP * dt
	}

	hole.curr_reach_multiplier = math.max(hole.curr_reach_multiplier, 0.0)
	hole.reach_radius =
		hole.base_reach_radius + (hole.base_reach_radius * hole.curr_reach_multiplier)

	hole_center(hole)
}

hole_center :: proc(hole: ^Hole) {
	hole.x = (rl.GetRenderWidth() / 2)
	hole.y = (rl.GetRenderHeight() / 2)
}

hole_attract_objects :: proc(hole: ^Hole, objects: ^Objects, toRemove: []int) #no_bounds_check {
	damp: f32 : 100.0

	toRemoveCount := 0

	halfSize := f32(objects.texture.width / 2)
	size2 := hole.size * hole.size


	holeOuterRadius := hole.size * hole.reach_radius

	objectWidth := f32(objects.texture.width)
	objectHeight := f32(objects.texture.height)

	for i in 0 ..< objects.length {

		if !intersects(
			f32(hole.x),
			f32(hole.y),
			holeOuterRadius,
			objects.x[i],
			objects.y[i],
			objectWidth,
			objectHeight,
		) {
			continue
		}

		holeInnerRadius := hole.size - (objectWidth * 2)
		if intersects(
			f32(hole.x),
			f32(hole.y),
			holeInnerRadius,
			objects.x[i],
			objects.y[i],
			objectWidth,
			objectHeight,
		) {
			toRemove[toRemoveCount] = i
			toRemoveCount += 1
			continue
		}

		dx := f32(hole.x) - objects.x[i]
		dy := f32(hole.y) - objects.y[i]

		d2 := dx * dx + dy * dy

		rx := dx * holeOuterRadius
		ry := dy * holeOuterRadius

		denom := d2 + damp
		inv_denom := 1.0 / denom
		strength := hole.mass * inv_denom


		objects.ax[i] = (dx * strength) / objects.mass[i]
		objects.ay[i] = (dy * strength) / objects.mass[i]
	}


	growth: f64 = 0.0
	index: int
	for i in 0 ..< toRemoveCount {
		index := toRemove[i]
		growth += f64(objects.mass[i]) * 0.001

		objects_remove(objects, index)
	}

	if growth > 0 {
		hole.size += f32(growth)
		hole_center(hole)
	}
}
