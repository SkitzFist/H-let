package game

import "core:fmt"
import rl "vendor:raylib"

ResourceType :: enum {
	DUST,
	HOLE,
}

Resources :: struct {
	values:   [ResourceType]int,
	unlocked: [ResourceType]bool,
}

ResourceGain :: struct {
	type:  ResourceType,
	value: int,
}

ResourceResultType :: enum {
	SUCCESS, //default value
	CANT_AFFORD,
}

Cost :: struct {
	type:  ResourceType,
	value: int,
}

RESOURCE_COLOR: [ResourceType]rl.Color = {
	.DUST = rl.BLUE,
	.HOLE = rl.BLACK,
}

resource_gain :: proc(resources: ^Resources, type: ResourceType, value: int) {
	resources.values[type] += value
}

resource_gain_multi :: proc(resources: ^Resources, resource_gains: [ResourceType]int) {
	for value, type in resource_gains {
		resources.values[type] += value

		if value > 0 {
			resources.unlocked[type] = true
		}

	}
}

@(private = "file")
resource_buy_single :: proc(resources: ^Resources, cost: Cost) -> bool {
	resources.values[cost.type] -= cost.value
	return true
}

@(private = "file")
resource_buy_multi :: proc(resources: ^Resources, costs: []Cost) -> (result: ResourceResultType) {

	for cost, i in costs {
		resources.values[cost.type] -= cost.value
	}

	return .SUCCESS
}

resource_buy :: proc {
	resource_buy_single,
	resource_buy_multi,
}


@(private = "file")
resource_can_buy_multi :: proc(
	resources: ^Resources,
	costs: []Cost,
) -> (
	result: ResourceResultType,
) {
	for cost in costs {
		if cost.value > resources.values[cost.type] {
			return .CANT_AFFORD
		}
	}

	return .SUCCESS
}

resource_can_buy :: proc {
	resource_can_buy_multi,
}

resources_unlocked :: proc(costs: []Cost) -> bool {
	for &cost in costs {
		if !g.resources.unlocked[cost.type] {
			return false
		}
	}

	return true
}


resource_draw :: proc(resources: ^Resources) {
	texts: [len(ResourceType)]cstring
	values: [len(ResourceType)]cstring
	types: [len(ResourceType)]ResourceType
	size := 0
	for type in ResourceType {

		if resources.unlocked[type] == false {
			continue
		}


		text := fmt.enum_value_to_string(type) or_continue
		texts[size] = fmt.caprintf("%s:", text, allocator = context.temp_allocator)

		values[size] = fmt.caprintf(
			"%i",
			resources.values[type],
			allocator = context.temp_allocator,
		)

		types[size] = type

		size += 1
	}

	if size == 0 {
		return
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
		f32(size) * ELEM_PADDING_Y + (f32(FRAME_INNER_PADDING) * 2),
	}

	rl.DrawRectangleLinesEx(frame, 2.0, rl.RAYWHITE)

	FONT_SIZE :: 20
	for i in 0 ..< size {

		rl.DrawText(
			texts[i],
			i32(frame.x) + FRAME_INNER_PADDING,
			i32(frame.y) + FRAME_INNER_PADDING + i32((f32(i) * ELEM_PADDING_Y)),
			FONT_SIZE,
			RESOURCE_COLOR[types[i]],
		)

		value_width := rl.MeasureText(values[i], FONT_SIZE)
		rl.DrawText(
			values[i],
			end_x - value_width - FRAME_INNER_PADDING,
			i32(frame.y) + FRAME_INNER_PADDING + i32((f32(i) * ELEM_PADDING_Y)),
			FONT_SIZE,
			rl.WHITE,
		)
	}

	rl.DrawCircle(end_x, y, 2.0, rl.YELLOW)
}

