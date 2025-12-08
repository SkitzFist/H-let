package game

import rl "vendor:raylib"


ButtonStyle :: struct {
	color:      rl.Color,
	text_color: rl.Color,
	font_size:  i32,
}


Button :: struct {
	x, y, width, height: f32,
	text:                cstring,
	func:                proc(),
	style:               ButtonStyle,
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

		style := &button.style
		text_size := rl.MeasureTextEx(rl.GetFontDefault(), button.text, f32(style.font_size), 1.0)
		x, y :=
			i32(button.x + (button.width / 2 - text_size.x / 2)),
			i32(button.y + (button.height / 2 - text_size.y / 2))

		rl.DrawRectangleRounded(
			{button.x, button.y, button.width, button.height},
			1.0,
			32,
			style.color,
		)

		rl.DrawText(button.text, x, y, style.font_size, style.text_color)
	}
}

