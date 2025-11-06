package game

import "base:intrinsics"
import c "components"
import "core:math"
import rl "vendor:raylib"

//debug
import "core:fmt"


objects_add :: #force_inline proc(
	positions: ^#soa[dynamic]c.Position,
	position: c.Position,
	physics: ^#soa[dynamic]c.Physic,
	physic: c.Physic,
	sizes: ^#soa[dynamic]c.Size,
	size: c.Size,
	textures: ^[dynamic]Texture,
	texture: Texture,
) {

	n, err := append_soa(positions, position)

	n1, err1 := append_soa(physics, physic)
	if n != n1 {
		panic(
			"[Objects]objects_add: {Physics} indexes does not match up, entities are out of sync!",
		)
	}

	n1, err1 = append_soa(sizes, size)
	if n != n1 {
		panic("[Objects]objects_add: {Sizes} indexes does not match up, entities are out of sync!")
	}

	append(textures, texture)
}

objects_remove :: #force_inline proc(
	index: int,
	positions: ^#soa[dynamic]c.Position,
	physics: ^#soa[dynamic]c.Physic,
	sizes: ^#soa[dynamic]c.Size,
) {
	unordered_remove_soa(positions, index)
	unordered_remove_soa(physics, index)
	unordered_remove_soa(sizes, index)
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

	for i in 0 ..< length {
		vx[i] = intrinsics.fused_mul_add(ax[i], dt, vx[i])
		vy[i] = intrinsics.fused_mul_add(ay[i], dt, vy[i])

		ax[i] = 0
		ay[i] = 0

		px[i] = intrinsics.fused_mul_add(vx[i], dt, px[i])
		py[i] = intrinsics.fused_mul_add(vy[i], dt, py[i])
	}
}
