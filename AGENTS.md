# AGENTS.md

## Build Commands
- **Hot Reload (Development)**: `./build_hot_reload.sh run` - Builds with hot reload and runs
- **Web Build**: `./build_web.sh` - Builds for web, outputs to `build/web/`
- **Web Run**: `./run_web.sh` - Runs web build using emrun
- **Windows**: `build_windows.bat run` - Windows build with hot reload
- **Release**: `odin build src -strict-style -vet -o:game_release.bin`

## Code Style Guidelines
- **Language**: Odin programming language
- **Package Structure**: Main game logic in `game` package, components in `components` package
- **Imports**: Group core imports first, then vendor imports (e.g., `rl "vendor:raylib"`)
- **Naming**: 
  - Procedures: snake_case (e.g., `game_init`, `objects_create_default`)
  - Types: PascalCase (e.g., `Game_Memory`, `Objects`)
  - Constants: ALL_CAPS (e.g., `CAP`, `DLL_EXT`)
  - Variables: snake_case (e.g., `game_api_version`)
- **Exported Procedures**: Use `@(export)` directive for game API functions
- **Memory Management**: Use tracking allocator in development, explicit cleanup in shutdown
- **Error Handling**: Use multi-return values `(result, success)` pattern, `or_return` for early returns
- **Structures**: Use #soa for struct-of-arrays pattern in performance-critical code
- **Documentation**: Add comments explaining hot reload behavior and exported procedures

## Odin Language Specifics (Updated)
- **For loop syntax**: `for value, type in array` is valid syntax in Odin dev-25-11 - the order of parameters in the loop doesn't need to match the array element order
- **Enum bounds**: `len(EnumType)` is known at compile time, so arrays sized with `[len(EnumType)]Type` are guaranteed to be bounds-safe
- **Scene system**: `gameloop_on_enter()` intentionally does NOT spawn initial objects when returning from skill tree - objects persist in memory during scene switches for performance optimization with 100k+ objects
- **Resource system**: `resource_gain_multi` iteration order is correct as written - do not flag as bug