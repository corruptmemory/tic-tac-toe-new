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
Piece :: enum {
	Empty,
	X,
	O,
}

animating := true

winner : Piece = .Empty

board: raylib.Model
board_state: [9]Piece
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

draw_pieces :: proc() {
	for p, i in board_state {
		switch p {
			case .Empty:
			case .X:
				raylib.DrawModel(x_piece, piece_positions[i], 0.2, raylib.GRAY)
			case .O:
				raylib.DrawModel(o_piece, piece_positions[i], 0.2, raylib.GRAY)
		}
	}
}

game_over :: proc() -> bool {
	x_rows: [3]int
	x_cols: [3]int
	o_rows: [3]int
	o_cols: [3]int
	x_diag: [2]int
	o_diag: [2]int

	for y in 0..2 {
		for x in 0..2 {
			p := y*3+x
			switch board_state[p] {
			case .Empty:
			case .X:
				x_rows[y] += 1
				x_cols[x] += 1
				switch {
				case y == 0 && x == 0:
						x_diag[0] += 1
				case y == 0 && x == 2:
						x_diag[1] += 1
				case y == 1 && x == 1:
						x_diag[0] += 1
						x_diag[1] += 1
				case y == 2 && x == 0:
						x_diag[1] += 1
				case y == 2 && x == 2:
						x_diag[0] += 1
				}
			case .O:
				o_rows[y] += 1
				o_cols[x] += 1
				switch {
				case y == 0 && x == 0:
						o_diag[0] += 1
				case y == 0 && x == 2:
						o_diag[1] += 1
				case y == 1 && x == 1:
						o_diag[0] += 1
						o_diag[1] += 1
				case y == 2 && x == 0:
						o_diag[1] += 1
				case y == 2 && x == 2:
						o_diag[0] += 1
				}
			}
		}
	}

	for i in 0..2 {
		switch {
		case x_rows[i] == 3 || x_cols[i] == 3:
			winner = .X
			return true
		case o_rows[i] == 3 || o_cols[i] == 3:
			winner = .O
			return true
		}
	}

	for i in 0..1 {
		switch {
		case x_diag[i] == 3:
			winner = .X
			return true
		case o_diag[i] == 3:
			winner = .O
			return true
		}
	}

	for i in 0..<9 {
		if board_state[i] == .Empty {
			return false
		}
	}
	return true
}

find_open_position :: proc(row: int, col: int, bias: int) {
	cursor_position = row*3+col
	if board_state[cursor_position] == .Empty {
		return
	}
	// try to find an open position on the current row
	c := col
	for remaining := 2; remaining > 0; remaining -= 1 {
		if bias == -1 {
			c = (c+2)%3
		} else {
			c = (c+1)%3
		}
		cursor_position = row*3 + c
		if board_state[cursor_position] == .Empty {
			return
		}
	}
	cursor_position = ((row+1)%3)*3 + col
	for remaining := 7; remaining > 0; remaining -= 1 {
		if board_state[cursor_position] == .Empty {
			return
		}
		cursor_position = (cursor_position + 1)%9
	}
}

draw_game_over :: proc() {

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
			draw_pieces()
			if !animating && !game_over() {
				draw_cursor(frame_time)
			}
		raylib.EndMode3D()                // End 3d mode drawing, returns to orthographic 2d mode
	raylib.EndTextureMode()               // End drawing to texture (now we have a texture available for next passes)

	raylib.BeginDrawing()
		raylib.ClearBackground(raylib.RAYWHITE)
		raylib.DrawTextureRec(target.texture, raylib.Rectangle{ 0, 0, f32(target.texture.width), f32(-target.texture.height)}, raylib.Vector2{ 0, 0 }, raylib.WHITE)
		if !game_over() {
			switch current_player {
				case .X: raylib.DrawText("Player: X", 10, 10, 20, raylib.GRAY)
				case .O: raylib.DrawText("Player: O", 10, 10, 20, raylib.GRAY)
			}
		} else {
			raylib.DrawText("GAME OVER!", 10, 10, 20, raylib.GRAY)
			switch winner {
				case .Empty: raylib.DrawText("DRAW!", 10, 30, 20, raylib.GREEN)
				case .X: raylib.DrawText("WINNER: X!", 10, 30, 20, raylib.GREEN)
				case .O: raylib.DrawText("WINNER: O!", 10, 30, 20, raylib.GREEN)
			}
			raylib.DrawText("GAME OVER!", 10, 10, 20, raylib.GRAY)
			draw_game_over()
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
		if raylib.IsKeyPressed(raylib.KeyboardKey.Q) do break
		if !game_over() {
			row := cursor_position / 3
			col := cursor_position % 3
			switch {
				case raylib.IsKeyPressed(raylib.KeyboardKey.LEFT):
					col = (col + 2)%3
					find_open_position(row, col, -1)
				case raylib.IsKeyPressed(raylib.KeyboardKey.RIGHT):
					col = (col + 1)%3
					find_open_position(row, col, 1)
				case raylib.IsKeyPressed(raylib.KeyboardKey.DOWN):
					row = (row + 1)%3
					find_open_position(row, col, 1)
				case raylib.IsKeyPressed(raylib.KeyboardKey.UP):
					row = (row + 2)%3
					find_open_position(row, col, 1)
				case raylib.IsKeyPressed(raylib.KeyboardKey.SPACE):
					if !game_over() {
						cp := row*3+col
						switch current_player {
							case .X:
								board_state[cp] = .X
								current_player = .O
							case .O:
								board_state[cp] = .O
								current_player = .X
						}
						find_open_position(row, col, 1)
					}
			}
		} else {
			if raylib.IsKeyPressed(raylib.KeyboardKey.R) {
				winner = .Empty
				cursor_position = 0
				for i in 0..<len(board_state) {
					board_state[i] = .Empty
				}
				current_player = .X
				param = 0.0
				animating = true
			}
		}
		draw_board()
	}

	raylib.UnloadRenderTexture(target)
	raylib.UnloadModel(board)
	raylib.UnloadModel(x_piece)
	raylib.UnloadModel(o_piece)
	raylib.CloseWindow()
}