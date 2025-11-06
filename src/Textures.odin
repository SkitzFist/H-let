package game

import rl "vendor:raylib"

Texture :: enum {
	SQUARE,
	BACKGROUND,
}


create_texture :: proc() -> rl.Texture2D {
	renderTexture := rl.LoadRenderTexture(20, 20)

	rl.BeginTextureMode(renderTexture)
	rl.ClearBackground(rl.BLANK)
	rl.DrawRectangle(0, 0, 20, 20, rl.RED)
	rl.EndTextureMode()

	return renderTexture.texture
}
