package game
clamp :: proc(x, lo, hi: f32) -> f32 {
	if x < lo do return lo
	if x > hi do return hi
	return x
}


intersects :: proc(
	circleX, circleY, circleRadius, rectX, rectY, rectWidth, rectHeight: f32,
) -> bool {
	closest_x := clamp(circleX, rectX, rectX + rectWidth)
	closest_y := clamp(circleY, rectY, rectY + rectHeight)

	dx := circleX - closest_x
	dy := circleY - closest_y

	return (dx * dx + dy * dy) <= (circleRadius * circleRadius)
}
