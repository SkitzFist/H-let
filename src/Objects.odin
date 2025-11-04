package game

import "base:intrinsics"
import rl "vendor:raylib"

MAX_LENGTH :: 1000

Objects :: struct {
	x:       [MAX_LENGTH]f32,
	y:       [MAX_LENGTH]f32,
	vx:      [MAX_LENGTH]f32,
	vy:      [MAX_LENGTH]f32,
	ax:      [MAX_LENGTH]f32,
	ay:      [MAX_LENGTH]f32,
	mass:    [MAX_LENGTH]f32,
	length:  int,
	texture: rl.Texture2D,
}

objects_add :: proc(objects: ^Objects, x, y, mass: f32) {
	if objects.length == MAX_LENGTH {
		return
	}


	objects.x[objects.length] = x
	objects.y[objects.length] = y
	objects.mass[objects.length] = mass
	objects.length += 1
}

objects_remove :: proc(objects: ^Objects, i: int) {
	if objects.length == 0 {
		return
	}


	lastIndex := objects.length - 1
	objects.x[i] = objects.x[lastIndex]
	objects.y[i] = objects.y[lastIndex]
	objects.vx[i] = objects.vx[lastIndex]
	objects.vy[i] = objects.vy[lastIndex]
	objects.ax[i] = objects.ax[lastIndex]
	objects.ay[i] = objects.ay[lastIndex]

	objects.length -= 1
}

objects_apply_forces :: proc(objects: ^Objects, dt: f32) #no_bounds_check {
	for i in 0 ..< objects.length {
		// acc -> vec
		objects.vx[i] = intrinsics.fused_mul_add(objects.ax[i], dt, objects.vx[i])
		objects.vy[i] = intrinsics.fused_mul_add(objects.ay[i], dt, objects.vy[i])

		// vec -> pos
		objects.x[i] = intrinsics.fused_mul_add(objects.vx[i], dt, objects.x[i])
		objects.y[i] = intrinsics.fused_mul_add(objects.vy[i], dt, objects.y[i])
	}
}
