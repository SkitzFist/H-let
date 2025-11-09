package game

import rl "vendor:raylib"

TextureType :: enum {
	SQUARE,
	BACKGROUND,
	HOLE,
}

SingleTexture :: struct {
	type: TextureType,
	id:   int,
}

create_square :: proc() -> rl.Texture2D {
	renderTexture := rl.LoadRenderTexture(20, 20)

	rl.BeginTextureMode(renderTexture)
	rl.ClearBackground(rl.BLANK)
	rl.DrawRectangle(0, 0, 20, 20, rl.RED)
	rl.EndTextureMode()

	return renderTexture.texture
}

create_hole_texture :: proc() -> rl.Texture2D {
	size: i32 = 160
	renderTexture := rl.LoadRenderTexture(size, size)

	rl.BeginTextureMode(renderTexture)
	rl.ClearBackground(rl.BLANK)
	rl.DrawCircle(size / 2, size / 2, f32(size / 2.0), rl.BLACK)
	rl.EndTextureMode()

	return renderTexture.texture
}
