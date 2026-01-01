package game

import "base:intrinsics"
import "core:crypto/poly1305"
import "core:fmt"
import "core:simd"
import rl "vendor:raylib"

TILE_ROWS: i32 : 8
TILE_COLUMNS: i32 : 8
TILE_COUNT :: TILE_ROWS * TILE_COLUMNS

Tile :: struct {}

TileMap :: struct {
	start:   [TILE_COUNT]int,
	count:   [TILE_COUNT]int,
	objects: [dynamic]int,
}

tile_map_delete :: proc(tile_map: ^TileMap) {
	delete(tile_map.objects)
}

set_tile_index :: proc(tile_index: [^]int, x, y: [^]f32, length: int) {
	width := rl.GetRenderWidth()
	height := rl.GetRenderHeight()

	tile_width: f32 = f32(width) / f32(TILE_COLUMNS)
	tile_height: f32 = f32(height) / f32(TILE_ROWS)

	tile_x, tile_y: f32

	for i in 0 ..< length {
		tile_x = x[i] / f32(tile_width)
		tile_y = y[i] / f32(tile_height)

		tile_x = clamp(tile_x, 0, f32(TILE_COLUMNS - 1))
		tile_y = clamp(tile_y, 0, f32(TILE_ROWS - 1))

		index := int(tile_y * f32(TILE_COLUMNS) + tile_x)

		if index >= int(TILE_COUNT) || index < 0 {
			fmt.println("tile_x:", tile_x, "tile_y:", tile_y)
			fmt.println("index:", index, "i:", i)
			panic("INDEX OUT OF SCOPE")

		}

		tile_index[i] = index
	}
}

// TODO let's skip simd for now
set_tile_index_simd :: proc(tile_index: [^]int, x, y: [^]f32, length: int) {
	width := f32(rl.GetRenderWidth())
	height := f32(rl.GetRenderHeight())
	LANES :: 8
	tile_width: #simd[LANES]f32 = {
		0 ..< LANES = width / f32(TILE_COLUMNS),
	}

	tile_height: #simd[LANES]f32 = {
		0 ..< LANES = height / f32(TILE_ROWS),
	}

	tile_columns: #simd[LANES]i32 = {
		0 ..< LANES = TILE_COLUMNS,
	}

	obj_x, obj_y, tile_x, tile_y: #simd[LANES]f32
	index: #simd[LANES]int
	slice: [LANES]int

	i := 0
	for ; i + (LANES - 1) < length; i += LANES {
		obj_x = simd.from_slice(#simd[LANES]f32, x[i:i + LANES])
		obj_y = simd.from_slice(#simd[LANES]f32, y[i:i + LANES])

		tile_x = simd.div(obj_x, tile_width)
		tile_y = simd.div(obj_y, tile_height)

	}

}

build_tile_map :: proc(tileMap: ^TileMap, tile_index: [^]int, length: int) {
	tileMap.count = {}
	for i in 0 ..< length {
		tileMap.count[tile_index[i]] += 1
	}

	tileMap.start = {}
	current := 0
	// start at 1 as tile[0] always starts at 0
	for i in 1 ..< TILE_COUNT {
		current += tileMap.count[i - 1]
		tileMap.start[i] = current
	}

	//resize object list
	if len(tileMap.objects) < length {
		resize(&tileMap.objects, length)
	}

	tile_current: [TILE_COUNT]int
	tile, tile_map_index: int

	for i in 0 ..< length {
		tile = tile_index[i]
		tile_map_index = tileMap.start[tile] + tile_current[tile]

		tile_current[tile] += 1

		tileMap.objects[tile_map_index] = i
	}

}


draw_tile_map :: proc() {
	width := rl.GetRenderWidth()
	height := rl.GetRenderHeight()

	tile_width: i32 = width / TILE_COLUMNS
	tile_height: i32 = height / TILE_ROWS

	for i in 0 ..< TILE_ROWS {
		y := i32(i) * tile_height
		rl.DrawLine(0, y, width, y, rl.GREEN)
	}

	for i in 0 ..< TILE_COLUMNS {
		x := i32(i) * tile_width
		rl.DrawLine(x, 0, x, height, rl.GREEN)
	}

	mouse_pos := rl.GetScreenToWorld2D(rl.GetMousePosition(), game_camera())

	tile_x := i32(mouse_pos.x / f32(tile_width))
	tile_y := i32(mouse_pos.y / f32(tile_height))

	tile: rl.Rectangle = {
		f32(tile_x) * f32(tile_width),
		f32(tile_y) * f32(tile_height),
		f32(tile_width),
		f32(tile_height),
	}

	rl.DrawRectangleRec(tile, rl.YELLOW)

	index := int(tile_y * TILE_COLUMNS + tile_x)
	rl.DrawText(
		fmt.ctprintf("index: %i\ntile_x: %i\ntile_y: %i", index, tile_x, tile_y),
		i32(tile.x),
		i32(tile.y),
		30,
		rl.BLACK,
	)

}

