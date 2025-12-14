package game

import "core:fmt"
import "core:slice"
import "core:strings"

import rl "vendor:raylib"

@(private = "file")
ButtonMap :: enum {
	RESUME,
	ROUND_SCORE_OK,
}

SkillTree :: struct {
	nodes:     [NodeType]Node,
	pos:       [NodeType]rl.Vector2,
	node_size: rl.Vector2,
	on_mouse:  NodeType,
	buttons:   [ButtonMap]Button,
}

skill_tree_on_exit :: proc() {

}

skill_tree_on_enter :: proc() {
	//resource_gain_multi(&g.resources, g.round.resources_gained)
}

skill_tree_create_default :: proc() -> SkillTree {
	buttons: [ButtonMap]Button

	buttons = {
		.RESUME = {
			text = "Resume",
			visible = true,
			func = proc() {switch_scene(.GAME)},
			style = .NORMAL,
		},
		.ROUND_SCORE_OK = {
			text = "Ok",
			visible = false,
			func = proc() {switch_scene(.GAME)},
			style = .NORMAL,
		},
	}

	return {
		nodes = NODE_BANK,
		pos = {min(NodeType) ..= max(NodeType) = {-100, -100}},
		node_size = {40, 40},
		buttons = buttons,
	}
}

apply_node :: proc(node: ^Node) {

	node.level += 1

	switch &data in node.data {
	case BoolData:
		g.skills.bool[data.type] = data.value
	case FloatData:
		g.skills.float[data.type] += data.value
	case IntData:
		g.skills.int[data.type] += data.value
	case ActiveData:
		g.gameloop.actives.enabled += {data.type}
	case ActiveCooldownData:
		g.gameloop.actives.cooldown_reductions[data.type] += data.value
	}
}

get_new_pos :: proc(current: rl.Vector2, dir: Direction, spacing: f32) -> rl.Vector2 {
	pos: rl.Vector2

	switch dir {
	case .WEST:
		pos = {current.x - spacing, current.y}
	case .EAST:
		pos = {current.x + spacing, current.y}
	case .NORTH:
		pos = {current.x, current.y - spacing}
	case .SOUTH:
		pos = {current.x, current.y + spacing}
	}

	return pos
}

get_line :: proc(
	current: rl.Vector2,
	new_pos: rl.Vector2,
	dir: Direction,
	node_width, node_height: f32,
	spacing: f32,
) -> (
	start: rl.Vector2,
	end: rl.Vector2,
) {
	start = current
	end = new_pos

	switch dir {
	case .WEST:
		start.y += node_height / 2
		end.x += node_width
		end.y += node_height / 2
	case .EAST:
		end.y += node_height / 2
		start.x += node_width
		start.y += node_height / 2

	case .NORTH:
		start.x += node_width / 2
		end.x += node_width / 2
		end.y += node_height
	case .SOUTH:
		end.x += node_width / 2
		start.x += node_width / 2
		start.y += node_height
	}

	return start, end
}

skill_tree_input :: proc() {
	tree := &g.skillTree

	mouse_pos := rl.GetMousePosition()
	mouse_pos = rl.GetScreenToWorld2D(mouse_pos, game_camera())
	tree.on_mouse = .NONE
	for type in NodeType {
		if intersects_point_rect(
			mouse_pos.x,
			mouse_pos.y,
			tree.pos[type].x,
			tree.pos[type].y,
			tree.node_size.x,
			tree.node_size.y,
		) {
			tree.on_mouse = type
			break
		}
	}

	if rl.IsMouseButtonPressed(.LEFT) && tree.on_mouse != .NONE {

		node := &tree.nodes[tree.on_mouse]

		if node.level < node_max_level(node) &&
		   resource_can_buy(&g.resources, node.costs[node.level]) == .SUCCESS {

			resource_buy(&g.resources, node.costs[node.level])
			apply_node(node)
		}
	}

	button_index := button_input(slice.enumerated_array(&tree.buttons))

	if rl.IsMouseButtonPressed(.LEFT) && button_index != -1 {
		g.skillTree.buttons[ButtonMap(button_index)].func()
	}

}

skill_tree_update :: proc(dt: f32) {
	resume_button := &g.skillTree.buttons[.RESUME]

	//todo should be moved to on resize
	button_width := f32(rl.GetRenderWidth()) * 0.1
	button_height := f32(rl.GetRenderHeight()) * 0.05

	resume_button.x = f32(rl.GetRenderWidth()) / 2 - button_width / 2
	resume_button.y = f32(rl.GetRenderHeight()) - button_height * 3
	resume_button.width = button_width
	resume_button.height = button_height
}

skill_tree_render :: proc() {
	tree := &g.skillTree
	nodes := &tree.nodes
	pos := &tree.pos

	NODE_WIDTH := i32(tree.node_size.x)
	NODE_HEIGHT := i32(tree.node_size.y)
	NODE_SPACING :: 90
	NODE_BORDER_SIZE :: 4

	init_node: NodeType = .MAX_HOLE_COUNT_1

	pos[init_node] = {
		f32(rl.GetRenderWidth() / 2 - NODE_WIDTH / 2),
		f32(rl.GetRenderHeight() / 2 - NODE_HEIGHT / 2),
	}

	to_visit := make([dynamic]NodeType, 0, len(NodeType), context.temp_allocator)
	append(&to_visit, init_node)

	for type in to_visit {
		node := &nodes[type]
		x, y := i32(pos[type].x), i32(pos[type].y)

		frame_color: rl.Color

		if node.level == node_max_level(node) {
			frame_color = rl.BLUE
		} else {
			frame_color =
				node.level < node_max_level(node) && resource_can_buy(&g.resources, node.costs[node.level]) == .SUCCESS ? rl.GREEN : rl.RED
		}


		rl.DrawRectangle(
			x - (NODE_BORDER_SIZE / 2),
			y - (NODE_BORDER_SIZE / 2),
			NODE_WIDTH + NODE_BORDER_SIZE,
			NODE_HEIGHT + NODE_BORDER_SIZE,
			frame_color,
		)

		node_color :=
			node.level == node_max_level(node) ? rl.Color{130, 130, 130, 230} : rl.RAYWHITE
		rl.DrawRectangle(x, y, NODE_WIDTH, NODE_HEIGHT, node_color)

		if nodes[type].level > 0 {
			for connection in nodes[type].connections {
				connection_node := nodes[connection.type]
				// Will always do resource discovered check against first level
				resources_unlocked(connection_node.costs[0][:]) or_continue

				new_pos := get_new_pos(pos[type], connection.dir, NODE_SPACING)
				pos[connection.type] = new_pos

				lineStart, lineEnd := get_line(
					pos[type],
					new_pos,
					connection.dir,
					f32(NODE_WIDTH),
					f32(NODE_HEIGHT),
					NODE_SPACING,
				)

				rl.DrawLineV(lineStart, lineEnd, rl.GREEN)

				append(&to_visit, connection.type)
			}
		}
	}


	resource_draw(&g.resources)

	button_draw(slice.enumerated_array(&g.skillTree.buttons))

	draw_node_tool_tip(tree.on_mouse)

}

draw_node_tool_tip :: proc(type: NodeType) {
	if type == .NONE {
		return
	}

	tree := &g.skillTree
	node := &tree.nodes[type]

	mouse_pos := rl.GetMousePosition()
	mouse_pos = rl.GetScreenToWorld2D(mouse_pos, game_camera())

	FONT_SIZE :: 20
	FONT_SPACING :: 1.0
	FRAME_PADDING :: 4

	tool_tip_size := rl.MeasureTextEx(rl.GetFontDefault(), node.tool_tip, FONT_SIZE, FONT_SPACING)

	level_text := fmt.ctprintf("Level: %i / %i", node.level, node_max_level(node))

	print_costs := node.level < node_max_level(node)

	cost_text: cstring
	if print_costs {
		costs := node.costs[node.level]
		parts := make([]string, len(costs), context.temp_allocator)
		for cost, i in costs {
			type_text := fmt.enum_value_to_string(cost.type) or_else "Unknown"
			parts[i] = fmt.tprintf("[%s: %i]", type_text, cost.value)
		}

		cost_text = fmt.ctprintf(
			"Cost: %s",
			strings.join(parts, ", ", allocator = context.temp_allocator),
		)
	}


	rows: f32 = print_costs ? 5 : 4
	frame: rl.Rectangle = {
		width  = tool_tip_size.x * 1.15,
		height = (tool_tip_size.y * rows) + (2 * f32(FRAME_PADDING)),
	}
	MOUSE_TO_FRAME_PADDING_Y :: 4
	frame.x = mouse_pos.x - frame.width / 2
	frame.y = mouse_pos.y - frame.height - MOUSE_TO_FRAME_PADDING_Y

	header_width := f32(rl.MeasureText(node.header, FONT_SIZE))
	header_x := i32(frame.x + frame.width / 2 - header_width / 2)

	TEXT_SPACING :: 1

	rl.DrawRectangleRec(frame, rl.GRAY)

	rl.DrawText(node.header, header_x, i32(FRAME_PADDING + frame.y), FONT_SIZE, rl.RAYWHITE)
	rl.DrawText(
		level_text,
		i32(frame.x + FRAME_PADDING),
		i32(FRAME_PADDING + frame.y + tool_tip_size.y * 2 + TEXT_SPACING),
		FONT_SIZE,
		rl.RAYWHITE,
	)

	y_index: f32 = 3

	if print_costs {
		rl.DrawText(
			cost_text,
			i32(frame.x + FRAME_PADDING),
			i32(FRAME_PADDING + frame.y + tool_tip_size.y * 3 + TEXT_SPACING),
			FONT_SIZE,
			rl.RAYWHITE,
		)

		y_index += 1
	}


	rl.DrawText(
		node.tool_tip,
		i32(frame.x + FRAME_PADDING),
		i32(FRAME_PADDING + frame.y + tool_tip_size.y * y_index + TEXT_SPACING),
		FONT_SIZE,
		rl.RAYWHITE,
	)

}

