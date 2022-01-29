package main

import "core:log"
import "vendor:raylib"
import "core:math"

screen_width :: 1920
screen_height :: 1080
move_per_second : f32 : 1.0
target_fps :: 60
Player :: enum {
	X,
	O,
}
piece_positions := []raylib.Vector3{
	{ -0.066, 0.066, 0.0 },  { 0.0, 0.066, 0.0 },  { 0.066, 0.066, 0.0 },
	{ -0.066, 0.0, 0.0 },    { 0.0, 0.0, 0.0 },    { 0.066, 0.0, 0.0 },
	{ -0.066, -0.066, 0.0 }, { 0.0, -0.066, 0.0 }, { 0.066, -0.066, 0.0 },
}

animating := true

board: raylib.Model
x_piece: raylib.Model
o_piece: raylib.Model
target: raylib.RenderTexture2D
current_player: Player = .X

cursor_position : int = 0
cursor_alpha : f32 = 1.0
cursor_alpha_direction : f32 = -1.0
cursor_move_per_second : f32 : 2.0
cursor_base_color :: raylib.BLUE

// animation values
param : f32 = 0.0

approach :: proc(t: f32) -> f32 {
	p := f32(math.lerp(f32(-9.0), f32(5.0), t))
	return (-p + 5.0)/(p + 10.0)
}

draw_cursor :: proc(frame_time: f32) {
	model: raylib.Model
	switch current_player {
		case .X: model = x_piece
		case .O: model = o_piece
	}
	alpha : u8 = u8(cursor_alpha * 255)
	cursor_alpha += frame_time*cursor_move_per_second*cursor_alpha_direction
	if cursor_alpha_direction == -1.0 {
		cursor_alpha = max(cursor_alpha, 0.0)
		if cursor_alpha == 0.0 {
			cursor_alpha_direction = 1.0
		}
	} else {
		cursor_alpha = min(cursor_alpha, 1.0)
		if cursor_alpha == 1.0 {
			cursor_alpha_direction = -1.0
		}
	}
	color := cursor_base_color
	color.a = alpha
	pos := piece_positions[cursor_position]
	raylib.DrawModel(model, pos, 0.2, color)
}

draw_board :: proc() {
    camera := raylib.Camera{ { 0.0, 0.0, 0.25 }, { 0.0, 0.0, 0.0 }, { 0.0, 1.0, 0.0 }, 45.0, raylib.CameraProjection.PERSPECTIVE }
	position := raylib.Vector3{ 0.0, 0.0, 0.0 }

	frame_time := raylib.GetFrameTime()
	if animating {
		param = min(param + frame_time*move_per_second, 1.0)
		if param == 1.0 {
			animating = false
		}
		position[2] = approach(param)
	}
	raylib.BeginTextureMode(target)       // Enable drawing to texture
		raylib.ClearBackground(raylib.RAYWHITE)  // Clear texture background
		raylib.BeginMode3D(camera)        // Begin 3d mode drawing
			raylib.DrawModel(board, position, 0.2, raylib.RED)   // Draw 3d model with texture
			if !animating {
				draw_cursor(frame_time)
			}
		raylib.EndMode3D()                // End 3d mode drawing, returns to orthographic 2d mode
	raylib.EndTextureMode()               // End drawing to texture (now we have a texture available for next passes)

	raylib.BeginDrawing()
		raylib.ClearBackground(raylib.RAYWHITE)
		raylib.DrawTextureRec(target.texture, raylib.Rectangle{ 0, 0, f32(target.texture.width), f32(-target.texture.height)}, raylib.Vector2{ 0, 0 }, raylib.WHITE)
		switch current_player {
			case .X: raylib.DrawText("Player: X", 10, 10, 20, raylib.GRAY)
			case .O: raylib.DrawText("Player: O", 10, 10, 20, raylib.GRAY)
		}
	raylib.EndDrawing()
}



main :: proc() {
	context.logger = log.create_console_logger()
	log.debug("Hello from tic-tac-toe")
	raylib.InitWindow(screen_width, screen_height, "Bouncy text!")
	raylib.SetTargetFPS(target_fps)

	board = raylib.LoadModel("board.obj");
	x_piece = raylib.LoadModel("X.obj");
	o_piece = raylib.LoadModel("O.obj");
	target = raylib.LoadRenderTexture(screen_width, screen_height)

	for !raylib.WindowShouldClose() {
		row := cursor_position / 3
		col := cursor_position % 3
		switch {
			case raylib.IsKeyPressed(raylib.KeyboardKey.LEFT):
			col = (col + 2)%3
			case raylib.IsKeyPressed(raylib.KeyboardKey.RIGHT):
			col = (col + 1)%3
			case raylib.IsKeyPressed(raylib.KeyboardKey.DOWN):
			row = (row + 1)%3
			case raylib.IsKeyPressed(raylib.KeyboardKey.UP):
			row = (row + 2)%3
		}
		cursor_position = row*3+col
		draw_board()
	}

	raylib.UnloadRenderTexture(target)
	raylib.UnloadModel(board)
	raylib.UnloadModel(x_piece)
	raylib.UnloadModel(o_piece)
	raylib.CloseWindow()
}