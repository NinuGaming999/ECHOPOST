extends RefCounted

## Converts the operating system's display-safe rectangle from screen pixels
## into the game's stretched viewport coordinates. Returns the full viewport
## when a platform cannot provide usable safe-area or window metrics.
static func to_viewport_rect(
	viewport_size: Vector2,
	window_position: Vector2i,
	window_size: Vector2i,
	display_safe_area: Rect2i
) -> Rect2:
	var full_rect := Rect2(Vector2.ZERO, viewport_size)
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return full_rect
	if window_size.x <= 0 or window_size.y <= 0:
		return full_rect
	if display_safe_area.size.x <= 0 or display_safe_area.size.y <= 0:
		return full_rect

	var window_rect := Rect2i(window_position, window_size)
	var clipped_safe_area := display_safe_area.intersection(window_rect)
	if clipped_safe_area.size.x <= 0 or clipped_safe_area.size.y <= 0:
		return full_rect

	var scale := Vector2(
		viewport_size.x / float(window_size.x),
		viewport_size.y / float(window_size.y)
	)
	var local_position := Vector2(clipped_safe_area.position - window_position) * scale
	var local_size := Vector2(clipped_safe_area.size) * scale
	var safe_rect := Rect2(local_position, local_size)
	safe_rect.position.x = clampf(safe_rect.position.x, 0.0, viewport_size.x)
	safe_rect.position.y = clampf(safe_rect.position.y, 0.0, viewport_size.y)
	safe_rect.size.x = clampf(safe_rect.size.x, 0.0, viewport_size.x - safe_rect.position.x)
	safe_rect.size.y = clampf(safe_rect.size.y, 0.0, viewport_size.y - safe_rect.position.y)
	if safe_rect.size.x <= 0.0 or safe_rect.size.y <= 0.0:
		return full_rect
	return safe_rect
