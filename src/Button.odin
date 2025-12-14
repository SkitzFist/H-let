package game

import "core:math"
import "core:time"
import rl "vendor:raylib"

ButtonStyleType :: enum {
	NORMAL,
	ACTIVE,
}

//TODO split into buttonStyle and TextStyle, keep in separate arrays.
//     so we can seprate button drawing and text drawing into their own segments
//     so raylib doesn't have to texture switch between drawing rectangles and texts
ButtonStyle :: struct {
	color:      rl.Color,
	text_color: rl.Color,
	font_size:  i32,
}

BUTTON_STYLES: [ButtonStyleType]ButtonStyle = {
	.NORMAL = {color = rl.WHITE, text_color = rl.GRAY, font_size = 20},
	.ACTIVE = {},
}

Button :: struct {
	x, y, width, height: f32,
	text:                cstring,
	func:                proc(),
	style:               ButtonStyleType,
	visible:             bool,
}

button_input :: proc(buttons: []Button) -> int {
	mouse_pos := rl.GetMousePosition()
	mouse_pos = rl.GetScreenToWorld2D(mouse_pos, game_camera())

	for &button, i in buttons {
		if intersects_point_rect(
			mouse_pos.x,
			mouse_pos.y,
			button.x,
			button.y,
			button.width,
			button.height,
		) {
			return i
		}
	}

	return -1
}

button_input_soa :: proc(x: []f32, y: []f32, width: []f32, height: []f32, length: int) -> int {
	mouse_pos := rl.GetMousePosition()
	mouse_pos = rl.GetScreenToWorld2D(mouse_pos, game_camera())

	for i in 0 ..< length {
		if intersects_point_rect(mouse_pos.x, mouse_pos.y, x[i], y[i], width[i], height[i]) {
			return i
		}
	}

	return -1
}

button_draw :: proc(buttons: []Button) {
	for &button in buttons {
		if !button.visible {continue}

		style := &BUTTON_STYLES[button.style]
		text_size := rl.MeasureTextEx(rl.GetFontDefault(), button.text, f32(style.font_size), 1.0)
		text_x, text_y :=
			i32(button.x + (button.width / 2 - text_size.x / 2)),
			i32(button.y + (button.height / 2 - text_size.y / 2))

		rl.DrawRectangleRounded(
			{button.x, button.y, button.width, button.height},
			1.0,
			32,
			style.color,
		)

		rl.DrawText(button.text, text_x, text_y, style.font_size, style.text_color)
	}
}

button_draw_active :: proc(
	buttons: [ActiveType]Button,
	cooldowns: [ActiveType]Cooldown,
	cooldown_reductions: [ActiveType]f32,
	enabled: bit_set[ActiveType],
) {

	now := time.now()
	for button, type in buttons {
		if type in enabled {
			style := &BUTTON_STYLES[button.style]
			text_size := rl.MeasureTextEx(
				rl.GetFontDefault(),
				button.text,
				f32(style.font_size),
				1.0,
			)
			text_x, text_y :=
				i32(button.x + (button.width / 2 - text_size.x / 2)),
				i32(button.y + (button.height / 2 - text_size.y / 2))

			elapsed := f32(time.diff(cooldowns[type].last_used_at, now))
			cooldown := f32(cooldowns[type].cooldown) / cooldown_reductions[type]
			perc := math.min(1.0, elapsed / cooldown)

			rl.DrawRectangleRounded(
				{button.x, button.y, button.width, button.height},
				1.0,
				32,
				style.color,
			)

			rl.DrawRectangleRounded(
				{button.x, button.y, button.width * perc, button.height},
				1.0,
				32,
				rl.SKYBLUE,
			)
			rl.DrawText(button.text, text_x, text_y, style.font_size, style.text_color)

		}
	}
}

