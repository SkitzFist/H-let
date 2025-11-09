package game

import "base:intrinsics"

apply_forces :: proc(
	positions: ^#soa[dynamic]Position,
	physics: ^#soa[dynamic]Physic,
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
