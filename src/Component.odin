package game

ComponentType :: enum {
	NONE,
	POSITION,
	SIZE,
	PHYSIC,
	TEXTURE,
	ATTRACTOR,
}

Components :: struct {
	positions:      #soa[dynamic]Position,
	physics:        #soa[dynamic]Physic,
	sizes:          #soa[dynamic]Size,
	singleTextures: #soa[dynamic]SingleTexture,
	attractors:     #soa[dynamic]Attractor,
}

delete_components :: proc(c: ^Components) {
	delete(c.positions)
	delete(c.sizes)
	delete(c.physics)
	delete(c.singleTextures)
	delete(c.attractors)
}

add_component :: proc(ecs: ^Ecs, data: $E, id: int) {
	c := &ecs.components
	index, err := get_index(ecs.id[:], id)

	if err == .NO_RESULT {
		panic("[ECS/Component] add_component: trying to add component to non-existant entity")
	}

	type := component_type_of(E)
	ecs.component_set[index] += {type}


	when E == Position do append_soa_elem(&c.positions, data)
	when E == Size do append_soa_elem(&c.sizes, data)
	when E == Physic do append_soa_elem(&c.physics, data)
	when E == SingleTexture do append_soa_elem(&c.singleTextures, data)
	when E == Attractor do append_soa_elem(&c.attractors, data)
}

component_type_of :: proc($E: typeid) -> ComponentType {
	when E == Position do return .POSITION
	when E == Size do return .SIZE
	when E == Physic do return .PHYSIC
	when E == SingleTexture do return .TEXTURE
	when E == Attractor do return .ATTRACTOR
	return .NONE
}

remove_component :: proc(ecs: ^Ecs, id: int, type: ComponentType) {
	index, err := get_index(ecs.id[:], id)

	if err == .NO_RESULT {
		panic(
			"[ECS/Component] remove_component: trying to remove component from non-existant entity",
		)
	}

	remove_component_data(ecs, id, type, index)
	ecs.component_set[index] -= {type}
}

remove_component_data :: proc(
	ecs: ^Ecs,
	id: int,
	type: ComponentType,
	lastIndex: int,
) -> (
	index: int,
	error: EcsError,
) {
	c := &ecs.components
	switch type {
	case .NONE:
		panic("Entity ended up with .None as type")
	case .POSITION:
		length := len(c.positions)
		return remove_from_component(&c.positions, c.positions.id[0:length], id, lastIndex)
	case .SIZE:
		length := len(c.sizes)
		return remove_from_component(&c.sizes, c.sizes.id[0:length], id, lastIndex)
	case .PHYSIC:
		length := len(c.physics)
		return remove_from_component(&c.physics, c.physics.id[0:length], id, lastIndex)
	case .TEXTURE:
		length := len(c.singleTextures)
		return remove_from_component(&c.physics, c.singleTextures.id[0:length], id, lastIndex)
	case .ATTRACTOR:
		length := len(c.attractors)
		return remove_from_component(&c.physics, c.attractors.id[0:length], id, lastIndex)
	}

	return -1, .NO_TYPE
}

remove_from_component :: proc(
	soa: ^$T/#soa[dynamic]$E,
	idArr: []int,
	id: int,
	lastIndex: int,
) -> (
	index: int,
	error: EcsError,
) {
	index, error = get_index(idArr, id, lastIndex)

	if error == .NO_RESULT {
		return
	}

	unordered_remove_soa(soa, index)

	return index, error
}
