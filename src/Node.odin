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

ActiveData :: struct {
	type: ActiveType,
}

ActiveCooldownData :: struct {
	type:  ActiveType,
	value: f32,
}

Data :: union {
	BoolData,
	FloatData,
	IntData,
	ActiveData,
	ActiveCooldownData,
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
	OBJECT_SPAWN_RATE_1,
	HOLE_MASS_1,
	HOLE_GROWTH_RATE_1,
	HOLE_EVAPORATION_RATE_1,
	ACTIVE_SPAWN_DUST_ENABLE,
	ACTIVE_SPAWN_DUST_COOLDOWN_1,
	ACTIVE_SPAWN_DUST_AMOUNT_1,
	ACTIVE_SPAWN_DUST_AUTO_CAST,
}

node_max_level :: proc(node: ^Node) -> int {
	return len(node.costs)
}

NODE_BANK: [NodeType]Node = {
	.NONE = {},
	.MAX_HOLE_COUNT_1 = {
		data = IntData{type = .HOLE_MAX_HOLE_COUNT, value = 1},
		costs = {
			{{type = .DUST, value = 10}},
			{{type = .DUST, value = 1000}},
			{{type = .DUST, value = 5000}, {type = .HOLE, value = 50}},
		},
		connections = {
			{type = .HOLE_START_SIZE_1, dir = .NORTH},
			{type = .OBJECT_SPAWN_RATE_1, dir = .SOUTH},
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
			{{type = .DUST, value = 500}},
			{{type = .DUST, value = 1500}},
		},
		header = "Hole Start size",
		tool_tip = "Increase initial size: 50% per level",
		connections = {
			{type = .HOLE_GROWTH_RATE_1, dir = .WEST},
			{type = .HOLE_MASS_1, dir = .EAST},
			{type = .HOLE_EVAPORATION_RATE_1, dir = .NORTH},
		},
	},
	.OBJECT_SPAWN_RATE_1 = {
		data = FloatData{type = .OBJECT_SPAWN_RATE, value = 0.5},
		costs = {
			{{type = .DUST, value = 50}},
			{{type = .DUST, value = 60}},
			{{type = .DUST, value = 90}},
			{{type = .DUST, value = 110}},
			{{type = .DUST, value = 150}},
			{{type = .DUST, value = 200}},
			{{type = .DUST, value = 250}},
			{{type = .DUST, value = 300}},
			{{type = .DUST, value = 400}},
			{{type = .DUST, value = 450}},
			{{type = .DUST, value = 500}},
		},
		header = "Dust Spawn rate",
		tool_tip = "Increase dust spawn rate.  SPAWN_RATE / (1.0 + (0.5 * level))",
		connections = {{type = .ACTIVE_SPAWN_DUST_ENABLE, dir = .EAST}},
	},
	.HOLE_MASS_1 = {
		data = IntData{type = .HOLE_MASS, value = 500},
		costs = {
			{{type = .DUST, value = 100}},
			{{type = .DUST, value = 250}},
			{{type = .DUST, value = 500}},
			{{type = .DUST, value = 750}},
			{{type = .DUST, value = 1000}},
		},
		header = "Hole mass",
		tool_tip = "Increases Holes mass by 500 per level. Mass increases attraction force",
	},
	.HOLE_GROWTH_RATE_1 = {
		data = FloatData{type = .HOLE_GROWTH_RATE, value = 0.1},
		costs = {
			{{type = .DUST, value = 100}},
			{{type = .DUST, value = 250}},
			{{type = .DUST, value = 500}},
			{{type = .DUST, value = 750}},
			{{type = .DUST, value = 1500}},
			{{type = .DUST, value = 4000}},
		},
		header = "Hole growth rate",
		tool_tip = "Growth rate per swallowed dust. Increase by 10% per level",
	},
	.HOLE_EVAPORATION_RATE_1 = {
		data = FloatData{type = .HOLE_EVAPORATION_RATE, value = 0.1},
		costs = {
			{{type = .DUST, value = 150}},
			{{type = .DUST, value = 350}},
			{{type = .DUST, value = 600}},
			{{type = .DUST, value = 850}},
			{{type = .DUST, value = 1200}},
			{{type = .DUST, value = 2000}},
			{{type = .DUST, value = 4000}},
		},
		header = "Hole evaporation",
		tool_tip = "Decrease hole evaporation rate by 10% per level",
	},
	.ACTIVE_SPAWN_DUST_ENABLE = {
		data = ActiveData{type = .SPAWN_DUST},
		costs = {{{type = .DUST, value = 500}, {type = .HOLE, value = 10}}},
		header = "Active - Spawn Dust",
		tool_tip = "Active skill - Spawn Dust",
		connections = {
			{type = .ACTIVE_SPAWN_DUST_COOLDOWN_1, dir = .EAST},
			{type = .ACTIVE_SPAWN_DUST_AMOUNT_1, dir = .SOUTH},
		},
	},
	.ACTIVE_SPAWN_DUST_COOLDOWN_1 = {
		data = ActiveCooldownData{type = .SPAWN_DUST, value = 0.1},
		costs = {
			{{type = .DUST, value = 150}, {type = .HOLE, value = 1}},
			{{type = .DUST, value = 350}, {type = .HOLE, value = 2}},
			{{type = .DUST, value = 600}, {type = .HOLE, value = 3}},
			{{type = .DUST, value = 850}, {type = .HOLE, value = 4}},
			{{type = .DUST, value = 1200}, {type = .HOLE, value = 5}},
			{{type = .DUST, value = 2000}, {type = .HOLE, value = 6}},
			{{type = .DUST, value = 4000}, {type = .HOLE, value = 7}},
		},
		header = "Spawn Dust - Cooldown reduction",
		tool_tip = "Reduces cooldown by 10% for each level",
	},
	.ACTIVE_SPAWN_DUST_AMOUNT_1 = {
		data = IntData{type = .ACTIVE_SPAWN_DUST_AMOUNT, value = 250},
		costs = {
			{{type = .DUST, value = 150}, {type = .HOLE, value = 1}},
			{{type = .DUST, value = 350}, {type = .HOLE, value = 2}},
			{{type = .DUST, value = 600}, {type = .HOLE, value = 3}},
			{{type = .DUST, value = 850}, {type = .HOLE, value = 4}},
		},
		header = "Spawn Dust - Spawn amount",
		tool_tip = "Increase spawn amount by 250 per level",
	},
	.ACTIVE_SPAWN_DUST_AUTO_CAST = {
		data = BoolData{type = .ACTIVE_SPAWN_DUST_AUTO_CAST},
		costs = {{{type = .DUST, value = 10_000}, {type = .HOLE, value = 100}}},
		header = "Spawn Dust - Auto cast",
		tool_tip = "Enables autocasting whenever Skill is ready",
	},
}

