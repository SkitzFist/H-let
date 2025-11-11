package game

import "base:intrinsics"
import c "components"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"


objects_add_random :: #force_inline proc() {
	positions := &g.positions
	physics := &g.physics
	sizes := &g.sizes

	pos: c.Position = {
		x = rand.float32_range(0, f32(rl.GetRenderWidth())),
		y = rand.float32_range(0, f32(rl.GetRenderHeight())),
	}
	factor := rand.float32_range(1, 5)

	phys: c.Physic = {
		mass = 10 * factor,
	}

	size: c.Size = {
		width  = 1 * factor,
		height = 1 * factor,
	}

	n, err := append_soa(positions, pos)

	n1, err1 := append_soa(physics, phys)
	if n != n1 {
		panic(
			"[Objects]objects_add: {Physics} indexes does not match up, entities are out of sync!",
		)
	}

	n1, err1 = append_soa(sizes, size)
	if n != n1 {
		panic("[Objects]objects_add: {Sizes} indexes does not match up, entities are out of sync!")
	}
}

objects_remove :: #force_inline proc(
	index: int,
	positions: ^#soa[dynamic]c.Position,
	physics: ^#soa[dynamic]c.Physic,
	sizes: ^#soa[dynamic]c.Size,
) {
	if index > 0 && index < len(positions) {
		unordered_remove_soa(positions, index)
		unordered_remove_soa(physics, index)
		unordered_remove_soa(sizes, index)
	}
}

objects_apply_forces :: proc(
	positions: ^#soa[dynamic]c.Position,
	physics: ^#soa[dynamic]c.Physic,
	dt: f32,
) #no_bounds_check {


	length := len(positions^)

	px := positions.x
	py := positions.y

	vx := physics.vx
	vy := physics.vy
	ax := physics.ax
	ay := physics.ay

	lambda: f32 : 1.0

	for i in 0 ..< length {
		vx[i] = intrinsics.fused_mul_add(ax[i], dt, vx[i])
		vy[i] = intrinsics.fused_mul_add(ay[i], dt, vy[i])

		ax[i] = 0
		ay[i] = 0

		//apply friction
		vx[i] *= math.exp(-lambda * dt)
		vy[i] *= math.exp(-lambda * dt)

		px[i] = intrinsics.fused_mul_add(vx[i], dt, px[i])
		py[i] = intrinsics.fused_mul_add(vy[i], dt, py[i])

		if px[i] < 0 {
			px[i] = 0
			vx[i] *= -1
		} else if px[i] > f32(rl.GetRenderWidth()) {
			px[i] = f32(rl.GetRenderWidth())
			vx[i] *= -1
		}

		if py[i] < 0 {
			py[i] = 0
			vy[i] *= -1
		} else if py[i] > f32(rl.GetRenderHeight()) {
			py[i] = f32(rl.GetRenderHeight())
			vy[i] *= -1
		}
	}
}
