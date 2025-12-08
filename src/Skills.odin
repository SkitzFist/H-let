package game

FloatSkillType :: enum {
	OBJECT_SPAWN_RATE,
	HOLE_EVAPORATION_RATE,
	HOLE_GROWTH_RATE,
	HOLE_MAX_SIZE,
	HOLE_START_SIZE,
	HOLE_REACH_RADIUS,
}

BoolSkillType :: enum {}

IntSkillType :: enum {
	HOLE_MAX_HOLE_COUNT,
}

SkillType :: union {
	FloatSkillType,
	BoolSkillType,
	IntSkillType,
}

Skills :: struct {
	float: [FloatSkillType]f32,
	bool:  [BoolSkillType]bool,
	int:   [IntSkillType]int,
}

skills_create_default :: proc() -> Skills {
	return {
		float = {min(FloatSkillType) ..= max(FloatSkillType) = 1.0},
		int = {.HOLE_MAX_HOLE_COUNT = 1},
	}
}

