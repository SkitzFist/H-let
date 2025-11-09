package game

import "base:intrinsics"
import rl "vendor:raylib"

Attractor :: struct {
	damp:                f32,
	reach_radius_factor: f32,
	id:                  int,
}

attract :: proc(
	ecs: ^Ecs,
	attractors: ^#soa[dynamic]Attractor,
	positions: ^#soa[dynamic]Position,
	sizes: ^#soa[dynamic]Size,
	physics: ^#soa[dynamic]Physic,
) #no_bounds_check {

	px := positions.x
	py := positions.y
	pl := len(positions^)
	p_id := positions.id[0:pl]

	sw := sizes.width
	sh := sizes.height

	ax := physics.ax
	ay := physics.ay
	mass := physics.mass
	props := physics.properties
	phl := len(physics^)
	phys_id := physics.id[0:phl]

	err: EcsError

	reach_radius: f32
	dx, dy, d2, strength, denom: f32

	for &attractor in attractors {

		index, e := get_index(p_id[:], attractor.id, -1)

		reach_radius = ((sw[index] + sh[index]) / 2) * attractor.reach_radius_factor
		for other_id, o_index in phys_id[0:] {

			if !intersects(
				px[index],
				py[index],
				reach_radius,
				px[o_index],
				py[o_index],
				sw[o_index],
				sh[o_index],
			) {
				continue
			}

			dx = px[index] - px[o_index]
			dy = py[index] - py[o_index]
			d2 = dx * dx + dy * dy

			strength = mass[index]

			if PhysProperties.DENOM in props[o_index] {
				denom = d2 + attractor.damp
				strength /= denom
			}

			ax[o_index] += (dx * strength) / mass[o_index]
			ay[o_index] += (dy * strength) / mass[o_index]
		}

	}
}

draw_attract_radius :: proc(
	ecs: ^Ecs,
	attractors: ^#soa[dynamic]Attractor,
	positions: ^#soa[dynamic]Position,
	sizes: ^#soa[dynamic]Size,
) {
	px := positions.x
	py := positions.y
	pl := len(positions^)
	p_id := positions.id[0:pl]

	sw := sizes.width
	sh := sizes.height
	sl := len(sizes^)
	s_id := sizes.id[0:sl]

	index: int
	reach_radius: f32
	err: EcsError

	for &attractor in attractors {

		if !has_component(ecs, attractor.id, .POSITION) ||
		   !has_component(ecs, attractor.id, .SIZE) ||
		   !has_component(ecs, attractor.id, .PHYSIC) {
			continue
		}

		index, err = get_index(p_id[:], attractor.id, -1)

		reach_radius = ((sw[index] + sh[index]) / 2) * attractor.reach_radius_factor
		rl.DrawCircleLines(i32(px[index]), i32(py[index]), reach_radius, rl.BLUE)
	}
}
