package game

import "core:time"

//debug
import rl "vendor:raylib"

ActiveType :: enum {
	SPAWN_DUST,
}

Cooldown :: struct {
	cooldown:     time.Duration, // in seconds
	last_used_at: time.Time,
}

Actives :: struct {
	cooldowns:  [ActiveType]Cooldown,
	active_use: [ActiveType]proc(),
	enabled:    bit_set[ActiveType],
	buttons:    [ActiveType]Button,
}

actives_create_default :: proc() -> Actives {
	return {
		cooldowns = {.SPAWN_DUST = {cooldown = time.Second * 10}},
		active_use = {.SPAWN_DUST = active_spawn_dust},
		buttons = {
			.SPAWN_DUST = {
				text   = "SPAWN_DUST",
				style  = .NORMAL, //debug
				x      = f32(rl.GetRenderWidth()) * 0.30,
				y      = f32(rl.GetRenderHeight()) - 50,
				width  = 200,
				height = 30.0,
			},
		},
		enabled = {.SPAWN_DUST},
	}
}

active_spawn_dust :: proc() {
	max_mid := g.skills.int[.ACTIVE_SPAWN_DUST_AMOUNT] / 10

	for i in 0 ..< g.skills.int[.ACTIVE_SPAWN_DUST_AMOUNT] {
		if i < max_mid {
			objects_add_random_mid(OBJECT_BASE_SIZE)
		}
		objects_add_random()
	}
}

