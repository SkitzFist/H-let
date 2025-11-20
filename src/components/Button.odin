package components

import rl "vendor:raylib"

ButtonStyle :: struct {
	color:      rl.Color,
	text_color: rl.Color,
	font_size:  i32,
}

Button :: struct {
	x, y, width, height: f32,
	text:                cstring,
	visible:             bool,
	hover:               bool,
	func:                proc(),
	style:               ButtonStyle,
}

draw_button :: proc(buttons: #soa[]Button) {
	for &button in buttons {
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
