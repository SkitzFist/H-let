/*
This file is the starting point of your game.

Some important procedures are:
- game_init_window: Opens the window
- game_init: Sets up the game state
- game_update: Run once per frame
- game_should_close: For stopping your game when close button is pressed
- game_shutdown: Shuts down game and frees memory
- game_shutdown_window: Closes window

The procs above are used regardless if you compile using the `build_release`
script or the `build_hot_reload` script. However, in the hot reload case, the
contents of this file is compiled as part of `build/hot_reload/game.dll` (or
.dylib/.so on mac/linux). In the hot reload cases some other procedures are
also used in order to facilitate the hot reload functionality:

- game_memory: Run just before a hot reload. That way game_hot_reload.exe has a
	pointer to the game's memory that it can hand to the new game DLL.
- game_hot_reloaded: Run after a hot reload so that the `g` global
	variable can be set to whatever pointer it was in the old DLL.

NOTE: When compiled as part of `build_release`, `build_debug` or `build_web`
then this whole package is just treated as a normal Odin package. No DLL is
created.
*/

package game

import "core:mem"
import "core:time"
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
	holeManager: HoleManager,
	gameloop:    Gameloop,
	objects:     #soa[dynamic]Object,
	objectStats: ObjectStats,
	skills:      Skills,
	skillTree:   SkillTree,
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

	g^ = Game_Memory {
		run         = true,
		objects     = make(#soa[dynamic]Object, 0, CAP, context.allocator),
		gameloop    = gameloop_create_default(),
		objectStats = object_stats_create_default(),
		holeManager = hole_manager_create_default(),
		textures    = create_texture_default(),
		skills      = skills_create_default(),
		skillTree   = skill_tree_create_default(),
	}


	if len(g.objects) == 0 {
		init_holes := 0
		init_obj := 1000

		for i in 0 ..< init_holes {
			append(&g.holeManager.holes, hole_create_default())
		}


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
			on_enter = gameloop_on_enter,
			on_exit  = game_loop_on_exit,
			input    = gameloop_input,
			update   = gameloop_update,
			render   = gameloop_render,
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


update_times, input_times, render_times: [100]time.Duration
update_time, input_time, render_time: f64

frames: i64

@(export)
game_update :: proc() {
	dt := rl.GetFrameTime()
	frames += 1


	if rl.IsKeyPressed(.ESCAPE) {
		g.run = false
		return
	}
	start := time.now()
	g.scene.input()
	input_times[frames % 100] = time.diff(start, time.now())
	input_time = calc_average_ms(input_times[:])

	start = time.now()
	g.scene.update(dt)
	update_times[frames % 100] = time.diff(start, time.now())
	update_time = calc_average_ms(update_times[:])

	rl.BeginDrawing()
	bgr_col: rl.Color = {10, 10, 10, 100}
	rl.ClearBackground(bgr_col)
	start = time.now()
	g.scene.render()
	render_times[frames % 100] = time.diff(start, time.now())
	render_time = calc_average_ms(render_times[:])

	rl.EndDrawing()

	// Everything on tracking allocator is valid until end-of-frame.
	free_all(context.temp_allocator)
}

calc_average_ms :: proc(times: []time.Duration) -> f64 {

	sum: f64

	for time in times {
		sum += f64(time)
	}

	return (sum / f64(len(times))) / 1_000_000
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

