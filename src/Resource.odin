package game

import "core:fmt"
import rl "vendor:raylib"

ResourceType :: enum {
	DUST,
}

Resources :: struct {
	values: [ResourceType]int,
}

ResourceGain :: struct {
	type:  ResourceType,
	value: int,
}

RESOURCE_COLOR: [ResourceType]rl.Color = {
	.DUST = rl.BLUE,
}

resource_gain :: proc(resources: ^Resources, type: ResourceType, value: int) {
	resources.values[type] += value
}

resource_draw :: proc(resources: ^Resources) {
	texts: [ResourceType]cstring
	values: [ResourceType]cstring

	for type in ResourceType {
		text := fmt.enum_value_to_string(type) or_continue
		texts[type] = fmt.caprintf("%s:", text, allocator = context.temp_allocator)

		values[type] = fmt.caprintf(
			"%i",
			resources.values[type],
			allocator = context.temp_allocator,
		)
	}

	start_x: i32 = i32(f32(rl.GetRenderWidth()) * 0.90)
	end_x := rl.GetRenderWidth() - 10
	frame_width := end_x - start_x
	FRAME_INNER_PADDING: i32 : 10

	y: i32 = 2
	ELEM_PADDING_Y: f32 = 30

	frame: rl.Rectangle = {
		f32(start_x),
		f32(y),
		f32(frame_width),
		len(ResourceType) * ELEM_PADDING_Y + (f32(FRAME_INNER_PADDING) * 2),
	}

	rl.DrawRectangleLinesEx(frame, 2.0, rl.RAYWHITE)

	FONT_SIZE :: 20
	for type, i in ResourceType {
		rl.DrawText(
			texts[type],
			i32(frame.x) + FRAME_INNER_PADDING,
			i32(frame.y) + FRAME_INNER_PADDING + i32((f32(i) * ELEM_PADDING_Y)),
			FONT_SIZE,
			RESOURCE_COLOR[type],
		)

		value_width := rl.MeasureText(values[type], FONT_SIZE)
		rl.DrawText(
			values[type],
			end_x - value_width - FRAME_INNER_PADDING,
			i32(frame.y) + FRAME_INNER_PADDING + i32((f32(i) * ELEM_PADDING_Y)),
			FONT_SIZE,
			rl.WHITE,
		)
	}

	rl.DrawCircle(end_x, y, 2.0, rl.YELLOW)
}
