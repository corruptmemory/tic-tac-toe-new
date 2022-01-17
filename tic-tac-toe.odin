package main

import "core:log"
import "vendor:raylib"
import "core:math"

screen_width :: 1920
screen_height :: 1080
move_per_second :: 180
target_fps :: 60

main :: proc() {
	context.logger = log.create_console_logger()
	log.debug("Hello from tic-tac-toe")
	raylib.InitWindow(screen_width, screen_height, "Bouncy text!")
	raylib.SetTargetFPS(target_fps)

	img := raylib.ImageText("Congrats! You created your first window!", 48, raylib.DARKGRAY)
	textTexture := raylib.LoadTextureFromImage(img)
	log.debugf("img: %v", img)
	iwidth := img.width
	iheight := img.height
	raylib.UnloadImage(img)
	defer raylib.UnloadTexture(textTexture)

	dir_x:i32 = 1
	dir_y:i32 = 1
	x:i32 = 190
	y:i32 = 200
	background:u32 = 0

	for !raylib.WindowShouldClose() {
		raylib.BeginDrawing()
			bg := raylib.ColorFromHSV(f32(background % 360), 1.0, 1.0)
			raylib.ClearBackground(bg)
			background += 3
			raylib.DrawTexture(textTexture, x, y, raylib.DARKGRAY)
			delta_x := i32(math.round(raylib.GetFrameTime()*f32(move_per_second*dir_x)))
			delta_y := i32(math.round(raylib.GetFrameTime()*f32(move_per_second*dir_y)))
			new_x := x + delta_x
			new_y := y + delta_y
			if (new_x + iwidth) < screen_width && new_x > 0 {
				x = new_x
			} else {
				dir_x = -dir_x
			}
			if (new_y + iheight) < screen_height && new_y > 0 {
				y = new_y
			} else {
				dir_y = -dir_y
			}
		raylib.EndDrawing()
	}
	raylib.CloseWindow()
}