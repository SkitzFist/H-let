package game

import "core:math/rand"
import rl "vendor:raylib"

Object :: struct {
	x, y, ax, ay, vx, vy, mass, width, height:f32,
	resource_drop : ResourceGain,
	tile_index:int
}

ObjectStats :: struct {
	spawn_rate: f32,
}

object_stats_create_default :: proc() -> ObjectStats {
	return {spawn_rate = 0.5}
}

OBJECT_BASE_SIZE :: 2
OBJECT_BASE_MASS :: 1

objects_add_random :: #force_inline proc() {

	factor := rand.float32_range(1, 5)

	object: Object = {
		x = rand.float32_range(0, f32(rl.GetRenderWidth())),
		y = rand.float32_range(0, f32(rl.GetRenderHeight())),
		mass = OBJECT_BASE_MASS * factor,
		width = OBJECT_BASE_SIZE * factor,
		height = OBJECT_BASE_SIZE * factor,
		resource_drop = {type = .DUST, value = 1},
	}

	append_soa(&g.objects, object)
}

objects_remove :: #force_inline proc(index: int) {
	unordered_remove_soa(&g.objects, index)
}

