package game
clamp :: proc(x, lo, hi: f32) -> f32 {
	if x < lo do return lo
	if x > hi do return hi
	return x
}


intersects_circle_rect :: proc(
	circleX, circleY, circleRadius, rectX, rectY, rectWidth, rectHeight: f32,
) -> bool {
	closest_x := clamp(circleX, rectX, rectX + rectWidth)
	closest_y := clamp(circleY, rectY, rectY + rectHeight)

	dx := circleX - closest_x
	dy := circleY - closest_y

	return (dx * dx + dy * dy) <= (circleRadius * circleRadius)
}

intersects_circle_circle :: proc(x1, y1, r1: f32, x2, y2, r2: f32) -> bool {
	dx := x2 - x1
	dy := y2 - y1
	dist_sq := dx * dx + dy * dy
	radius_sum := r1 + r2
	return dist_sq <= radius_sum * radius_sum
}

intersects_point_rect :: proc(px, py, rx, ry, rw, rh: f32) -> bool {
	return !(px > rx + rw || px < rx || py > ry + rh || py < ry)
}


intersects :: proc {
	intersects_circle_rect,
	intersects_circle_circle,
}
