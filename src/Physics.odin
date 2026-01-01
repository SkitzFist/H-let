package game

import "base:intrinsics"
import "core:math"
import "core:simd"
import rl "vendor:raylib"

attract :: proc(
	attract_x, attract_y, attract_mass, attract_ax, attract_ay: [^]f32,
	other_x, other_y, other_mass, other_ax, other_ay: [^]f32,
	attract_length, other_length: int,
	G: f32 = 1.0,
) #no_bounds_check {
	dx, dy, r2, force, strength: f32
	for a in 0 ..< attract_length {
		for o in 0 ..< other_length {

			dx = attract_x[a] - other_x[o]
			dy = attract_y[a] - other_y[o]

			r2 = dx * dx + dy * dy
			force = (attract_mass[a] * other_mass[o]) / r2
			force *= G

			strength = force / other_mass[o]
			other_ax[o] += (dx * strength)
			other_ay[o] += (dy * strength)

			strength = force / attract_mass[a]
			attract_ax[a] += (-dx * strength)
			attract_ay[a] += (-dy * strength)
		}
	}
}

attract_same :: proc(x, y, mass, ax, ay: [^]f32, length: int, G: f32 = 1.0) #no_bounds_check {
	dx, dy, r2, force, strength: f32
	for a in 0 ..< length {
		for o in (a + 1) ..< length {
			dx = x[a] - x[o]
			dy = y[a] - y[o]

			r2 = dx * dx + dy * dy
			force = (mass[a] * mass[o]) / r2
			force *= G

			strength = force / mass[o]
			ax[o] += (dx * strength)
			ay[o] += (dy * strength)

			strength = force / mass[a]
			ax[a] += (-dx * strength)
			ay[a] += (-dy * strength)
		}
	}
}

attract_same_simd :: proc(x, y, mass, ax, ay: [^]f32, length: int, G: f32 = 1.0) #no_bounds_check {
	LANES :: 8
	a_x, a_y, a_ax, a_ay, a_mass: #simd[LANES]f32
	o_x, o_y, o_ax, o_ay, o_mass: #simd[LANES]f32
	dx, dy, r2, force, strength: #simd[LANES]f32

	g: #simd[LANES]f32 = {
		0 ..< LANES = G,
	}

	for a := 0; a + 7 < length; a += 8 {
		a_x = simd.from_slice(#simd[LANES]f32, x[a:a + LANES])
		a_y = simd.from_slice(#simd[LANES]f32, y[a:a + LANES])
		a_ax = simd.from_slice(#simd[LANES]f32, ax[a:a + LANES])
		a_ay = simd.from_slice(#simd[LANES]f32, ay[a:a + LANES])
		a_mass = simd.from_slice(#simd[LANES]f32, mass[a:a + LANES])

		o := a + 8
		for ; o + 7 < length; o += 8 {
			o_x = simd.from_slice(#simd[LANES]f32, x[o:o + LANES])
			o_y = simd.from_slice(#simd[LANES]f32, y[o:o + LANES])
			o_ax = simd.from_slice(#simd[LANES]f32, ax[o:o + LANES])
			o_ay = simd.from_slice(#simd[LANES]f32, ay[o:o + LANES])
			o_mass = simd.from_slice(#simd[LANES]f32, mass[o:o + LANES])


			dx = simd.sub(a_x, o_x)
			dy = simd.sub(a_y, o_y)

			r2 = simd.add(simd.mul(dx, dx), simd.mul(dy, dy))

			force = simd.div(simd.mul(a_mass, o_mass), r2)
			force = simd.mul(force, g)

		}
	}
}

apply_force :: proc(
	x, y, ax, ay, vx, vy: [^]f32,
	length: int,
	dt: f32,
	lambda: f32 = 1.0,
) #no_bounds_check {
	friction := math.exp(-lambda * dt)

	for i in 0 ..< length {
		// Apply acceleration
		vx[i] = intrinsics.fused_mul_add(ax[i], dt, vx[i])
		vy[i] = intrinsics.fused_mul_add(ay[i], dt, vy[i])

		ax[i] = 0
		ay[i] = 0

		//apply friction
		vx[i] *= friction
		vy[i] *= friction

		x[i] = intrinsics.fused_mul_add(vx[i], dt, x[i])
		y[i] = intrinsics.fused_mul_add(vy[i], dt, y[i])

		if x[i] < 0 {
			x[i] = 0
			vx[i] *= -1
		} else if x[i] > f32(rl.GetRenderWidth()) {
			x[i] = f32(rl.GetRenderWidth())
			vx[i] *= -1
		}

		if y[i] < 0 {
			y[i] = 0
			vy[i] *= -1
		} else if y[i] > f32(rl.GetRenderHeight()) {
			y[i] = f32(rl.GetRenderHeight())
			vy[i] *= -1
		}
	}
}

