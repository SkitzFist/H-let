package game

BoolData :: struct {
	type:  BoolSkillType,
	value: bool,
}

FloatData :: struct {
	type:  FloatSkillType,
	value: f32,
}

IntData :: struct {
	type:  IntSkillType,
	value: int,
}

Data :: union {
	BoolData,
	FloatData,
	IntData,
}

Direction :: enum {
	WEST,
	EAST,
	NORTH,
	SOUTH,
}

Connection :: struct {
	type: NodeType,
	dir:  Direction,
}

Level :: struct {
	costs: []Cost,
}

Node :: struct {
	data:        Data,
	costs:       [][]Cost,
	connections: []Connection,
	level:       int,
	header:      cstring,
	tool_tip:    cstring,
}

NodeType :: enum {
	NONE,
	MAX_HOLE_COUNT_1,
	HOLE_START_SIZE_1,
	OBJECT_INITIAL_AMOUNT_1,
	OBJECT_SPAWN_RATE_1,
	HOLE_REACH_RADIUS_1,
	HOLE_GROWTH_RATE_1,
	HOLE_EVAPORATION_RATE_1,
}

node_max_level :: proc(node: ^Node) -> int {
	return len(node.costs)
}

NODE_BANK: [NodeType]Node = {
	.NONE = {},
	.MAX_HOLE_COUNT_1 = {
		data = IntData{type = .HOLE_MAX_HOLE_COUNT, value = 1},
		costs = {{{type = .DUST, value = 10}}, {{type = .DUST, value = 1000}}},
		connections = {
			{.HOLE_START_SIZE_1, .NORTH},
			{type = .OBJECT_INITIAL_AMOUNT_1, dir = .SOUTH},
		},
		header = "Maximum holes",
		tool_tip = "Increase number of maximum holes by 1",
	},
	.HOLE_START_SIZE_1 = {
		data = FloatData{type = .HOLE_START_SIZE, value = 0.5},
		costs = {
			{{type = .DUST, value = 30}},
			{{type = .DUST, value = 70}},
			{{type = .DUST, value = 150}},
			{{type = .DUST, value = 1000}},
			{{type = .DUST, value = 3000}},
		},
		header = "Hole Start size",
		tool_tip = "Increase initial size: 50% per level",
	},
	.OBJECT_INITIAL_AMOUNT_1 = {
		data = IntData{type = .OBJECT_INITIAL_AMOUNT, value = 1000},
		costs = {{{type = .DUST, value = 90}}, {{type = .DUST, value = 1500}}},
		header = "Initial Dust amount",
		tool_tip = "Increase by 1000 dust per level",
	},
	.OBJECT_SPAWN_RATE_1 = {},
	.HOLE_REACH_RADIUS_1 = {},
	.HOLE_GROWTH_RATE_1 = {},
	.HOLE_EVAPORATION_RATE_1 = {},
}
