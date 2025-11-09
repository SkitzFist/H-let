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

import "components"
import "core:math/rand"
import "core:mem"
import rl "vendor:raylib"


CAP :: 1000
Game_Memory :: struct {
	holeManager: HoleManager,
	textures:    [Texture]rl.Texture2D,
	positions:   #soa[dynamic]components.Position,
	physics:     #soa[dynamic]components.Physic,
	sizes:       #soa[dynamic]components.Size,
	obj_texture: [dynamic]Texture,
	run:         bool,
}

g: ^Game_Memory

@(export)
game_init_window :: proc() {
	//rl.SetConfigFlags({.VSYNC_HINT})
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
		run = true,
		positions = make(#soa[dynamic]components.Position, 0, CAP, context.allocator),
		physics = make(#soa[dynamic]components.Physic, 0, CAP, context.allocator),
		sizes = make(#soa[dynamic]components.Size, 0, CAP, context.allocator),
		holeManager = {
			holes = make([dynamic]Hole, 0, 10, context.allocator),
			max = 5,
			current = 0,
			stats = {evaporationForce = 100, growth_rate = 0.005},
		},
		textures = {
			.SQUARE = create_texture(),
			.BACKGROUND = rl.LoadTexture("assets/Grass_1.png"),
		},
	}


	if len(g.positions) == 0 {
		init_count := CAP
		for i in 0 ..< init_count {
			pos: components.Position = {
				x = rand.float32_range(0, f32(rl.GetRenderWidth())),
				y = rand.float32_range(0, f32(rl.GetRenderHeight())),
			}
			phys: components.Physic = {
				mass = rand.float32_range(10, 50),
			}
			size: components.Size = {
				width  = f32(g.textures[.SQUARE].width),
				height = f32(g.textures[.SQUARE].height),
			}
			objects_add(
				&g.positions,
				pos,
				&g.physics,
				phys,
				&g.sizes,
				size,
				&g.obj_texture,
				.SQUARE,
			)
		}
	}

	game_hot_reloaded(g)
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
	input()
	update()

	rl.BeginDrawing()
	rl.ClearBackground(rl.GRAY)
	draw()
	rl.EndDrawing()

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

	delete(g.positions)
	delete(g.physics)
	delete(g.sizes)
	delete(g.obj_texture)
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
