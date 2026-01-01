package game

import "core:mem"
import rl "vendor:raylib"

CAP :: 10_000

SceneType :: enum {
	MENU,
	GAME,
	SKILL_TREE,
}

Scene :: struct {
	on_enter: proc(),
	on_exit:  proc(),
	input:    proc(),
	update:   proc(dt: f32),
	render:   proc(),
}

Game_Memory :: struct {
	scene:       Scene,
	tileMap:     TileMap,
	holeManager: HoleManager,
	skillTree:   SkillTree,
	gameloop:    Gameloop,
	objects:     #soa[dynamic]Object,
	objectStats: ObjectStats,
	skills:      Skills,
	resources:   Resources,
	textures:    [TextureType]rl.Texture2D,
	run:         bool,
}

g: ^Game_Memory

@(export)
game_init_window :: proc() {
	rl.SetConfigFlags({.BORDERLESS_WINDOWED_MODE, .WINDOW_MAXIMIZED, .WINDOW_RESIZABLE})
	monitor: i32 = 0
	width := rl.GetMonitorWidth(monitor)
	height := rl.GetMonitorHeight(monitor)
	rl.InitWindow(width, height, "Hålet")
	//rl.SetTargetFPS(500)
	rl.SetExitKey(nil)
}

@(export)
game_init :: proc() {
	g = new(Game_Memory)

	init_obj := 1000

	g^ = Game_Memory {
		run = true,
		objects = make(#soa[dynamic]Object, 0, CAP, context.allocator),
		tileMap = {objects = make([dynamic]int, init_obj, CAP, context.allocator)},
		gameloop = gameloop_create_default(),
		objectStats = object_stats_create_default(),
		holeManager = hole_manager_create_default(),
		textures = create_texture_default(),
		skills = skills_create_default(),
		skillTree = skill_tree_create_default(),
	}

	bench_init()

	if len(g.objects) == 0 {
		for j in 0 ..< init_obj {
			objects_add_random()
		}
	}

	if g.scene.input == nil {
		switch_scene(.GAME)
	}

	game_hot_reloaded(g)
}

switch_scene :: proc(type: SceneType) {
	if g.scene.on_exit != nil {
		g.scene.on_exit()
	}

	switch type {
	case .MENU:
		//not implemented yet
		fallthrough
	case .GAME:
		g.scene = {
			on_enter = game_loop_on_enter,
			on_exit  = game_loop_on_exit,
			input    = game_loop_input,
			update   = game_loop_update,
			render   = game_loop_render,
		}
	case .SKILL_TREE:
		g.scene = {
			on_enter = skill_tree_on_enter,
			on_exit  = skill_tree_on_exit,
			input    = skill_tree_input,
			update   = skill_tree_update,
			render   = skill_tree_render,
		}
	}

	if g.scene.on_enter != nil {
		g.scene.on_enter()
	}
}

game_camera :: proc() -> rl.Camera2D {
	w := f32(rl.GetScreenWidth())
	h := f32(rl.GetScreenHeight())

	return {zoom = 1.0, target = {0.0, 0.0}}
}

ui_camera :: proc() -> rl.Camera2D {
	return {zoom = 1.0}
}

@(export)
game_update :: proc() {
	dt := rl.GetFrameTime()

	if rl.IsKeyPressed(.ESCAPE) {
		g.run = false
		return
	}

	bench_start("input")
	g.scene.input()
	bench_end()

	bench_start("update")
	g.scene.update(dt)
	bench_end()

	rl.BeginDrawing()
	bgr_col: rl.Color = {10, 10, 10, 100}
	rl.ClearBackground(bgr_col)
	bench_start("render")
	g.scene.render()
	bench_end()
	rl.EndDrawing()

	bench_frame_end()
	// Everything on tracking allocator is valid until end-of-frame.
	free_all(context.temp_allocator)
}

@(export)
game_should_run :: proc() -> bool {
	when ODIN_OS != .JS {
		// Never run this proc in browser. It contains a 16 ms sleep on web!
		if rl.WindowShouldClose() {
			return false
		}
	}

	return g.run
}

@(export)
game_shutdown :: proc() {
	for &texture in g.textures {
		rl.UnloadTexture(texture)
	}

	delete(g.objects)
	delete(g.holeManager.holes)
	tile_map_delete(&g.tileMap)
	bench_delete()

	free(g)
}

@(export)
game_shutdown_window :: proc() {
	rl.CloseWindow()
}

@(export)
game_memory :: proc() -> rawptr {
	return g
}

@(export)
game_memory_size :: proc() -> int {
	return size_of(Game_Memory)
}

@(export)
game_hot_reloaded :: proc(mem: rawptr) {
	g = (^Game_Memory)(mem)

	// Here you can also set your own global variables. A good idea is to make
	// your global variables into pointers that point to something inside `g`.
}

@(export)
game_force_reload :: proc() -> bool {
	return rl.IsKeyPressed(.F5)
}

@(export)
game_force_restart :: proc() -> bool {
	return rl.IsKeyPressed(.F6)
}

// In a web build, this is called when browser changes size. Remove the
// `rl.SetWindowSize` call if you don't want a resizable game.
game_parent_window_size_changed :: proc(w, h: int) {
	rl.SetWindowSize(i32(w), i32(h))
}

