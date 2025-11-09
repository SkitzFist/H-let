package game

import rl "vendor:raylib"

draw_single_texture :: proc(
	textureBank: [TextureType]rl.Texture2D,
	singleTextures: ^#soa[dynamic]SingleTexture,
	positions: ^#soa[dynamic]Position,
	sizes: ^#soa[dynamic]Size,
) {
	px := &positions.x
	py := &positions.y
	pid := &positions.id
	pl := len(positions^)

	sw := sizes.width
	sh := sizes.height
	sid := sizes.id
	sl := len(sizes^)

	id: int

	src: rl.Rectangle
	dst: rl.Rectangle
	//index := -1
	err: EcsError
	x, y: f32
	w, h: f32

	origin: rl.Vector2
	rotation: f32 : 0.0

	for &texture, index in singleTextures {
		id = texture.id

		// // get pos
		// index, err = get_index(pid[0:pl], id, index)
		// if err == .NO_RESULT {
		// 	panic("[DrawSingleTexture] Position index not found")
		// }
		x, y = px[index], py[index]

		// // get size
		// index, err = get_index(sid[0:sl], id, index)
		// if err == .NO_RESULT {
		// 	panic("[DrawSingleTexture] Size index not found")
		// }
		w, h = sw[index], sh[index]

		src.width = f32(textureBank[texture.type].width)
		src.height = f32(textureBank[texture.type].height)

		dst = {x, y, w, h}
		origin = {w / 2, h / 2}

		rl.DrawTexturePro(textureBank[texture.type], src, dst, origin, rotation, rl.WHITE)
	}
}
