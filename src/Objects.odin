package game

import "base:intrinsics"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

Object :: struct {
	using pos:           Position,
	using phys:          Physic,
	using size:          Size,
	using resource_drop: ResourceGain,
}

ObjectStats :: struct {
	spawn_rate: f32,
}

object_stats_create_default :: proc() -> ObjectStats {
	return {spawn_rate = 0.5}
}

OBJECT_BASE_SIZE :: 2
OBJECT_BASE_MASS :: 100

objects_add_random :: #force_inline proc() {

	factor := rand.float32_range(1, 5)

	object: Object = {
		pos = {
			x = rand.float32_range(0, f32(rl.GetRenderWidth())),
			y = rand.float32_range(0, f32(rl.GetRenderHeight())),
		},
		phys = {mass = OBJECT_BASE_MASS * factor},
		size = {width = OBJECT_BASE_SIZE * factor, height = OBJECT_BASE_SIZE * factor},
		resource_drop = {type = .DUST, value = 1},
	}

	append_soa(&g.objects, object)
}

objects_add_random_mid :: proc(sizeFactor: f32) {
	width := f32(rl.GetRenderWidth()) * sizeFactor
	height := f32(rl.GetRenderHeight()) * sizeFactor

	rect: rl.Rectangle = {
		x      = (f32(rl.GetRenderWidth()) / 2) - (width / 2),
		y      = (f32(rl.GetRenderHeight()) / 2) - (height / 2),
		width  = width,
		height = height,
	}

	factor := rand.float32_range(1, 5)

	object: Object = {
		pos = {
			x = rand.float32_range(rect.x, rect.x + rect.width),
			y = rand.float32_range(rect.y, rect.y + rect.height),
		},
		phys = {mass = OBJECT_BASE_MASS * factor},
		size = {width = OBJECT_BASE_SIZE * factor, height = OBJECT_BASE_SIZE * factor},
		resource_drop = {type = .DUST, value = 1},
	}

	append_soa(&g.objects, object)
}

objects_remove :: #force_inline proc(index: int) {
	unordered_remove_soa(&g.objects, index)
}

objects_apply_forces :: proc(
	pos: [^]Position,
	phys: [^]Physic,
	length: int,
	dt: f32,
) #no_bounds_check {

	lambda: f32 : 1.0
	friction := math.exp(-lambda * dt)

	for i in 0 ..< length {
		phys[i].vx = intrinsics.fused_mul_add(phys[i].ax, dt, phys[i].vx)
		phys[i].vy = intrinsics.fused_mul_add(phys[i].ay, dt, phys[i].vy)

		phys[i].ax = 0
		phys[i].ay = 0

		//apply friction
		phys[i].vx *= friction
		phys[i].vy *= friction

		pos[i].x = intrinsics.fused_mul_add(phys[i].vx, dt, pos[i].x)
		pos[i].y = intrinsics.fused_mul_add(phys[i].vy, dt, pos[i].y)

		if pos[i].x < 0 {
			pos[i].x = 0
			phys[i].vx *= -1
		} else if pos[i].x > f32(rl.GetRenderWidth()) {
			pos[i].x = f32(rl.GetRenderWidth())
			phys[i].vx *= -1
		}

		if pos[i].y < 0 {
			pos[i].y = 0
			phys[i].vy *= -1
		} else if pos[i].y > f32(rl.GetRenderHeight()) {
			pos[i].y = f32(rl.GetRenderHeight())
			phys[i].vy *= -1
		}
	}
}

objects_update_rotation :: proc(rotations: ^#soa[dynamic]Rotation, dt: f32) {

	// rotation := &rotations.rotation
	// speed := &rotations.speed

	// LANES :: 8
	// rotation_reg: #simd[LANES]f32
	// speed_reg: #simd[LANES]f32
	// speed_dt: #simd[LANES]f32

	// dt_reg: #simd[LANES]f32 = {
	// 	0 ..< LANES = dt,
	// }

	// slice: [LANES]f32
	// i := 0

	// for ; i + LANES < len(rotations); i += LANES {
	// 	speed_reg = simd.from_slice(#simd[LANES]f32, speed[i:i + LANES])

	// 	speed_dt = simd.mul(dt_reg, speed_reg)


	// 	rotation_reg = simd.from_slice(#simd[LANES]f32, rotation[i:i + LANES])
	// 	updated_rotation: #simd[LANES]f32 = simd.add(rotation_reg, speed_dt)

	// 	slice = simd.to_array(updated_rotation)
	// 	copy(rotation[i:i + LANES], slice[:])
	// }
}

