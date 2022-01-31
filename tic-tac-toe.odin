package main

import "core:log"
import "vendor:raylib"
import "core:math"
import "core:mem"
import "core:c"

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
Search_Direction :: enum {
	Up,
	Down,
	Left,
	Right,
}

animating := true

winner : Piece = .Empty
winning_col := -1
winning_row := -1
winning_diag := -1

starfield: raylib.Shader
board_and_pieces: raylib.Shader
iTime: c.int
camera: raylib.Camera
board: raylib.Model
board_state: [9]Piece
x_piece: raylib.Model
o_piece: raylib.Model
target: raylib.RenderTexture2D
blank_texture: raylib.Texture2D
current_player: Player = .X

board_background:: raylib.Color{ 0, 0, 0, 200 }

cursor_position : int = 0
cursor_alpha : f32 = 1.0
cursor_alpha_direction : f32 = -1.0
cursor_move_per_second : f32 : 2.0
cursor_base_color :: raylib.Color{ 0, 60, 120, 255 }

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
			if x_rows[i] == 3 {
				winning_row = i
			} else {
				winning_col = i
			}
			return true
		case o_rows[i] == 3 || o_cols[i] == 3:
			winner = .O
			if o_rows[i] == 3 {
				winning_row = i
			} else {
				winning_col = i
			}
			return true
		}
	}

	for i in 0..1 {
		switch {
		case x_diag[i] == 3:
			winner = .X
			winning_diag = i
			return true
		case o_diag[i] == 3:
			winner = .O
			winning_diag = i
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

find_open_position :: proc(row: int, col: int, direction: Search_Direction) {
	// try to find an open position on the current row
	c := col
	r := row
	switch direction {
	case .Up:
		cursor_position = ((r+2)%3)*3+c
		if board_state[cursor_position] == .Empty do return
		cursor_position = ((r+1)%3)*3+c
		if board_state[cursor_position] == .Empty do return
		cursor_position = ((r+2)%3)*3+(c+2)%3
		if board_state[cursor_position] == .Empty do return
		cursor_position = ((r+2)%3)*3+(c+1)%3
		if board_state[cursor_position] == .Empty do return
		cursor_position = ((r+1)%3)*3+(c+2)%3
		if board_state[cursor_position] == .Empty do return
		cursor_position = ((r+1)%3)*3+(c+1)%3
		if board_state[cursor_position] == .Empty do return
	case .Down:
		cursor_position = ((r+1)%3)*3+c
		if board_state[cursor_position] == .Empty do return
		cursor_position = ((r+2)%3)*3+c
		if board_state[cursor_position] == .Empty do return
		cursor_position = ((r+1)%3)*3+(c+2)%3
		if board_state[cursor_position] == .Empty do return
		cursor_position = ((r+1)%3)*3+(c+1)%3
		if board_state[cursor_position] == .Empty do return
		cursor_position = ((r+2)%3)*3+(c+2)%3
		if board_state[cursor_position] == .Empty do return
		cursor_position = ((r+2)%3)*3+(c+1)%3
		if board_state[cursor_position] == .Empty do return
	case .Left:
		cursor_position = r*3+(c+2)%3
		if board_state[cursor_position] == .Empty do return
		cursor_position = r*3+(c+1)%3
		if board_state[cursor_position] == .Empty do return
		cursor_position = ((r+2)%3)*3+(c+2)%3
		if board_state[cursor_position] == .Empty do return
		cursor_position = ((r+2)%3)*3+(c+1)%3
		if board_state[cursor_position] == .Empty do return
		cursor_position = ((r+1)%3)*3+(c+2)%3
		if board_state[cursor_position] == .Empty do return
		cursor_position = ((r+1)%3)*3+(c+1)%3
		if board_state[cursor_position] == .Empty do return
	case .Right:
		cursor_position = r*3+(c+1)%3
		if board_state[cursor_position] == .Empty do return
		cursor_position = r*3+(c+2)%3
		if board_state[cursor_position] == .Empty do return
		cursor_position = ((r+1)%3)*3+(c+1)%3
		if board_state[cursor_position] == .Empty do return
		cursor_position = ((r+1)%3)*3+(c+2)%3
		if board_state[cursor_position] == .Empty do return
		cursor_position = ((r+2)%3)*3+(c+1)%3
		if board_state[cursor_position] == .Empty do return
		cursor_position = ((r+2)%3)*3+(c+2)%3
		if board_state[cursor_position] == .Empty do return
	}
	if board_state[cursor_position] != .Empty {
		for i in 0..<len(board_state) {
			cursor_position = i
			if board_state[cursor_position] == .Empty do return
		}
	}
}

draw_game_over :: proc() {
	if winning_col > -1 {
		st := piece_positions[winning_col]
		st[1] += 0.030
		ed := piece_positions[winning_col+6]
		ed[1] -= 0.030
		sp := raylib.GetWorldToScreen(st, camera)
		ep := raylib.GetWorldToScreen(ed, camera)
		raylib.DrawLineEx(sp, ep, 20.0, raylib.GREEN)
	} else if winning_row > -1 {
		st := piece_positions[winning_row*3]
		st[0] -= 0.030
		ed := piece_positions[winning_row*3+2]
		ed[0] += 0.030
		sp := raylib.GetWorldToScreen(st, camera)
		ep := raylib.GetWorldToScreen(ed, camera)
		raylib.DrawLineEx(sp, ep, 20.0, raylib.GREEN)
	} else if winning_diag > -1 {
		st, ed: raylib.Vector3
		switch winning_diag {
		case 0:
			st = piece_positions[0]
			st[0] -= 0.030
			st[1] += 0.030
			ed = piece_positions[8]
			ed[0] += 0.030
			ed[1] -= 0.030
		case 1:
			st = piece_positions[2]
			st[0] += 0.030
			st[1] += 0.030
			ed = piece_positions[6]
			ed[0] -= 0.030
			ed[1] -= 0.030
		}
		sp := raylib.GetWorldToScreen(st, camera)
		ep := raylib.GetWorldToScreen(ed, camera)
		raylib.DrawLineEx(sp, ep, 20.0, raylib.GREEN)
	}
}

draw_board :: proc() {
	position := raylib.Vector3{ 0.0, 0.0, 0.0 }

	frame_time := raylib.GetFrameTime()
	itime := f32(raylib.GetTime())
    raylib.SetShaderValue(starfield, raylib.ShaderLocationIndex(iTime), &itime, raylib.ShaderUniformDataType.FLOAT)
	if animating {
		param = min(param + frame_time*move_per_second, 1.0)
		if param == 1.0 {
			animating = false
		}
		position[2] = approach(param)
	}
	raylib.BeginTextureMode(target)       // Enable drawing to texture
		raylib.ClearBackground(board_background)  // Clear texture background
		raylib.BeginMode3D(camera)        // Begin 3d mode drawing
			raylib.DrawModel(board, position, 0.2, raylib.RED)   // Draw 3d model with texture
			draw_pieces()
			if !animating && !game_over() {
				draw_cursor(frame_time)
			}
		raylib.EndMode3D()                // End 3d mode drawing, returns to orthographic 2d mode
	raylib.EndTextureMode()               // End drawing to texture (now we have a texture available for next passes)

	raylib.BeginDrawing()
		raylib.BeginShaderMode(starfield)
			raylib.DrawTextureRec(blank_texture, raylib.Rectangle{ 0, 0, f32(blank_texture.width), f32(-blank_texture.height)}, raylib.Vector2{ 0, 0 }, raylib.WHITE)
		raylib.EndShaderMode()
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
	raylib.InitWindow(screen_width, screen_height, "-- COSMIC TIC-TAC-TOE --")
	raylib.SetTargetFPS(target_fps)

    camera = raylib.Camera{ { 0.0, 0.0, 0.25 }, { 0.0, 0.0, 0.0 }, { 0.0, 1.0, 0.0 }, 45.0, raylib.CameraProjection.PERSPECTIVE }
	board = raylib.LoadModel("board.obj");
	x_piece = raylib.LoadModel("X.obj");
	o_piece = raylib.LoadModel("O.obj");
	target = raylib.LoadRenderTexture(screen_width, screen_height)
	starfield = raylib.LoadShader(nil, "resources/shaders/starfield.fs")
	board_and_pieces = raylib.LoadShader("resources/shaders/piece_and_board.vs", "resources/shaders/piece_and_board.fs")
	blank := raylib.GenImageColor(screen_width, screen_height, raylib.BLANK)
    blank_texture = raylib.LoadTextureFromImage(blank)
    raylib.UnloadImage(blank)
    board.materials[0].shader = board_and_pieces
    x_piece.materials[0].shader = board_and_pieces
    o_piece.materials[0].shader = board_and_pieces

    iResolution := raylib.GetShaderLocation(starfield, "iResolution")
    screen_dims := []f32{ f32(screen_width), f32(screen_height) }
    raylib.SetShaderValue(starfield, raylib.ShaderLocationIndex(iResolution), mem.raw_data(screen_dims), raylib.ShaderUniformDataType.VEC2)
    iTime = raylib.GetShaderLocation(starfield, "iTime")

    lightPos := raylib.GetShaderLocation(board_and_pieces, "lightPos")
    light_pos := []f32{ 0.0, 0.0, 0.25 }
    raylib.SetShaderValue(board_and_pieces, raylib.ShaderLocationIndex(lightPos), mem.raw_data(light_pos), raylib.ShaderUniformDataType.VEC3)

	for !raylib.WindowShouldClose() {
		if raylib.IsKeyPressed(raylib.KeyboardKey.Q) do break
		if !game_over() {
			row := cursor_position / 3
			col := cursor_position % 3
			switch {
				case raylib.IsKeyPressed(raylib.KeyboardKey.LEFT):
					find_open_position(row, col, .Left)
				case raylib.IsKeyPressed(raylib.KeyboardKey.RIGHT):
					find_open_position(row, col, .Right)
				case raylib.IsKeyPressed(raylib.KeyboardKey.DOWN):
					find_open_position(row, col, .Down)
				case raylib.IsKeyPressed(raylib.KeyboardKey.UP):
					find_open_position(row, col, .Up)
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
						find_open_position(row, col, .Right)
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
				winning_col = -1
				winning_row = -1
				winning_diag = -1
			}
		}
		draw_board()
	}

	raylib.UnloadRenderTexture(target)
	raylib.UnloadShader(board_and_pieces)
	raylib.UnloadShader(starfield)
	raylib.UnloadModel(board)
	raylib.UnloadModel(x_piece)
	raylib.UnloadModel(o_piece)
	raylib.CloseWindow()
}