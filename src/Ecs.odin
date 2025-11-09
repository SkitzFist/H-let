package game

EcsError :: enum {
	NONE,
	NO_RESULT,
	NO_TYPE,
}

Ecs :: struct {
	component_set: [dynamic]bit_set[ComponentType],
	id:            [dynamic]int,
	components:    Components,
	next_id:       int,
}

delete_ecs :: proc(ecs: ^Ecs) {
	delete(ecs.id)
	delete(ecs.component_set)

	delete_components(&ecs.components)
}

create_entity :: proc(ecs: ^Ecs) -> (id: int, error: EcsError) {
	id = ecs.next_id
	ecs.next_id += 1

	append_elem(&ecs.id, id)
	append_nothing(&ecs.component_set)

	return id, .NONE
}

remove :: proc(ecs: ^Ecs, id: int) -> EcsError {

	main_index, err := get_index(ecs.id[:], id)

	if err == .NO_RESULT {
		return .NO_RESULT
	}

	//remove all components
	lastIndex := main_index
	for type in ComponentType {
		if type in ecs.component_set[main_index] {
			lastIndex, err = remove_component_data(ecs, id, type, lastIndex)
		}
	}

	//remove from component_set & id
	unordered_remove(&ecs.component_set, main_index)
	unordered_remove(&ecs.id, main_index)

	return .NONE
}

index_shortcut: f64 = 0
index_n_shortcut: f64 = 0

get_index :: proc(idArr: []int, id: int, lastIndex: int = -1) -> (int, EcsError) {

	if lastIndex < len(idArr) && lastIndex >= 0 {
		index_shortcut += 1
		if idArr[lastIndex] == id {return lastIndex, .NONE}
	}

	index_n_shortcut += 1

	index := binary_search(idArr, id)
	err := EcsError.NONE

	if index == -1 {
		err = .NO_RESULT
	}

	return index, err
}

binary_search :: proc(arr: []int, target: int) -> int {
	left := 0
	right := len(arr) - 1

	for left <= right {
		mid := (left + right) / 2
		value := arr[mid]

		if value == target {
			return mid
		} else if value < target {
			left = mid + 1
		} else {
			right = mid - 1
		}
	}

	return -1
}

has_component :: proc(ecs: ^Ecs, id: int, type: ComponentType) -> bool {
	index, err := get_index(ecs.id[:], id)

	if err == .NO_RESULT {
		return false
	}

	return type in ecs.component_set[index]
}
