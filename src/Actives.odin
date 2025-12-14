package game

import "core:slice"
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
	cooldowns:           [ActiveType]Cooldown,
	cooldown_reductions: [ActiveType]f32,
	active_use:          [ActiveType]proc(),
	enabled:             bit_set[ActiveType],
	buttons:             [ActiveType]Button,
}

actives_create_default :: proc() -> Actives {
	return {
		cooldowns = {.SPAWN_DUST = {cooldown = time.Second * 10}},
		cooldown_reductions = {min(ActiveType) ..= max(ActiveType) = 1.0},
		active_use = {.SPAWN_DUST = active_spawn_dust},
		buttons = {
			.SPAWN_DUST = {
				text   = "SPAWN_DUST",
				style  = .NORMAL,
				//debug position placement
				x      = f32(rl.GetRenderWidth()) * 0.30,
				y      = f32(rl.GetRenderHeight()) - 50,
				width  = 200,
				height = 30.0,
			},
		},
		enabled = {},
	}
}

actives_input :: proc(actives: ^Actives) -> int {

	now := time.now()
	//collision detection
	index := button_input(slice.enumerated_array(&actives.buttons))

	if index != -1 && rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
		type := ActiveType(index)
		elapsed := f32(time.diff(actives.cooldowns[type].last_used_at, now))
		cooldown := f32(actives.cooldowns[type].cooldown) / actives.cooldown_reductions[type]
		can_use := elapsed >= cooldown

		if can_use {
			actives.cooldowns[type].last_used_at = time.now()
			//TODO when done prototyping, don't trigger actives from input, add to queue and trigger in update
			actives.active_use[type]()
		}
	}

	return index
}

active_spawn_dust :: proc() {
	for i in 0 ..< g.skills.int[.ACTIVE_SPAWN_DUST_AMOUNT] {
		objects_add_random()
	}
}

