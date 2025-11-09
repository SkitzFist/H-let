package game

PhysProperties :: enum {
	DENOM,
}

Physic :: struct {
	vx, vy, ax, ay, mass: f32,
	properties:           bit_set[PhysProperties],
	id:                   int,
}
