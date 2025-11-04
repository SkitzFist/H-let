package game

import rl "vendor:raylib"


create_texture :: proc() -> rl.Texture2D {
	renderTexture := rl.LoadRenderTexture(20, 20)

	rl.BeginTextureMode(renderTexture)
	rl.ClearBackground(rl.BLANK)
	rl.DrawCircle(10, 10, 20, rl.RED)
	rl.EndTextureMode()

	return renderTexture.texture
}
