package game

import "core:math"
import rl "vendor:raylib"

TextureType :: enum {
	SQUARE,
	BACKGROUND,
	DUAL_GLOW,
}

create_texture_default :: proc() -> [TextureType]rl.Texture2D {
	return {
		.SQUARE = create_square(),
		.BACKGROUND = rl.LoadTexture("assets/warp.png"),
		.DUAL_GLOW = MakeDualRadialGlowTex(256, 0.1, 1.0, 0.05, 0.8),
	}
}

create_square :: proc() -> rl.Texture2D {
	renderTexture := rl.LoadRenderTexture(20, 20)

	rl.BeginTextureMode(renderTexture)
	rl.ClearBackground(rl.BLANK)
	rl.DrawRectangle(0, 0, 20, 20, rl.RED)
	rl.EndTextureMode()

	return renderTexture.texture
}

MakeRadialGlowTex :: proc(size: i32, inner: f32, outer: f32) -> rl.Texture2D {
	img := rl.GenImageColor(size, size, rl.BLANK)
	pixels := rl.LoadImageColors(img)
	defer rl.UnloadImage(img)

	center := rl.Vector2{f32(size) * 0.5, f32(size) * 0.5}
	R := f32(size) * 0.5
	r0 := inner * R
	r1 := outer * R

	for y in 0 ..< size {
		for x in 0 ..< size {
			d := rl.Vector2Distance(center, rl.Vector2{f32(x), f32(y)})
			t := (d - r0) / math.max(r1 - r0, 1e-6)
			falloff := 1.0 - math.clamp(t, 0.0, 1.0)
			falloff = falloff * falloff * (3 - 2 * falloff)
			a := cast(u8)(falloff * 255.0)
			pixels[y * size + x] = rl.Color{255, 255, 255, a}
		}
	}

	// Create texture
	tex := rl.LoadTextureFromImage(
		rl.Image {
			data = pixels,
			width = size,
			height = size,
			mipmaps = 1,
			format = rl.PixelFormat.UNCOMPRESSED_R8G8B8A8,
		},
	)

	rl.UnloadImageColors(pixels)
	rl.SetTextureFilter(tex, rl.TextureFilter.BILINEAR)
	return tex
}

MakeDualRadialGlowTex :: proc(
	size: i32,
	bot_inner, bot_outer, top_inner, top_outer: f32,
) -> rl.Texture2D {
	full_w := size * 2
	full_h := size

	// Start with a blank image and grab its pixel buffer
	img := rl.GenImageColor(full_w, full_h, rl.BLANK)
	pixels := rl.LoadImageColors(img)
	defer rl.UnloadImage(img)
	defer rl.UnloadImageColors(pixels)

	draw_glow := proc(offset_x: i32, inner, outer: f32, size, full_w: i32, pixels: [^]rl.Color) {
		center := rl.Vector2{f32(offset_x) + f32(size) * 0.5, f32(size) * 0.5}
		R := f32(size) * 0.5
		r0 := inner * R
		r1 := outer * R

		for y in 0 ..< size {
			base := y * full_w
			for x in 0 ..< size {
				// Distance from this glow's center
				d := rl.Vector2Distance(center, rl.Vector2{f32(offset_x + x), f32(y)})

				// Smoothstep falloff
				t := (d - r0) / math.max(r1 - r0, 1e-6)
				falloff := 1.0 - math.clamp(t, 0.0, 1.0)
				falloff = falloff * falloff * (3 - 2 * falloff)

				a := cast(u8)(falloff * 255.0)
				pixels[base + offset_x + x] = rl.Color{255, 255, 255, a}
			}
		}
	}

	// Left half = BOT, right half = TOP
	draw_glow(0, bot_inner, bot_outer, size, full_w, pixels)
	draw_glow(size, top_inner, top_outer, size, full_w, pixels)

	// Build texture
	tex := rl.LoadTextureFromImage(
		rl.Image {
			data = pixels,
			width = full_w,
			height = full_h,
			mipmaps = 1,
			format = rl.PixelFormat.UNCOMPRESSED_R8G8B8A8,
		},
	)

	rl.SetTextureFilter(tex, rl.TextureFilter.BILINEAR)
	return tex
}
