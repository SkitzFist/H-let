package game

import "base:intrinsics"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

import c "components"

Objects :: struct {
	positions:      #soa[dynamic]c.Position,
	physics:        #soa[dynamic]c.Physic,
	sizes:          #soa[dynamic]c.Size,
	resource_gains: #soa[dynamic]ResourceGain,
}

ObjectStats :: struct {
	spawn_rate: f32,
}


object_stats_create_default :: proc() -> ObjectStats {
	return {spawn_rate = 0.5}
}

objects_delete :: proc(objects: ^Objects) {
	delete(objects.physics)
	delete(objects.positions)
	delete(objects.sizes)
	delete(objects.resource_gains)
}

objects_add_random :: #force_inline proc() {

	positions := &g.objects.positions
	physics := &g.objects.physics
	sizes := &g.objects.sizes
	resource_gains := &g.objects.resource_gains

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

	resource_gain: ResourceGain = {
		type  = .DUST,
		value = 1,
	}

	append_soa(positions, pos)
	append_soa(physics, phys)
	append_soa(sizes, size)
	append_soa(resource_gains, resource_gain)
}

objects_add_random_mid :: proc(sizeFactor: f32) {
	positions := &g.objects.positions
	physics := &g.objects.physics
	sizes := &g.objects.sizes
	resource_gains := &g.objects.resource_gains

	width := f32(rl.GetRenderWidth()) * sizeFactor
	height := f32(rl.GetRenderHeight()) * sizeFactor

	rect: rl.Rectangle = {
		x      = (f32(rl.GetRenderWidth()) / 2) - (width / 2),
		y      = (f32(rl.GetRenderHeight()) / 2) - (height / 2),
		width  = width,
		height = height,
	}

	pos: c.Position = {
		x = rand.float32_range(rect.x, rect.x + rect.width),
		y = rand.float32_range(rect.y, rect.y + rect.height),
	}

	factor := rand.float32_range(1, 5)

	phys: c.Physic = {
		mass = 10 * factor,
	}

	size: c.Size = {
		width  = 1 * factor,
		height = 1 * factor,
	}

	resource_gain: ResourceGain = {
		type  = .DUST,
		value = 1,
	}

	append_soa(positions, pos)
	append_soa(physics, phys)
	append_soa(sizes, size)
	append_soa(resource_gains, resource_gain)
}

objects_remove :: #force_inline proc(index: int) {
	obj := &g.objects
	unordered_remove_soa(&obj.positions, index)
	unordered_remove_soa(&obj.physics, index)
	unordered_remove_soa(&obj.sizes, index)
	unordered_remove_soa(&obj.resource_gains, index)
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
