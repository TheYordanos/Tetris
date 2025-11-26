package main

import "core:math/rand"
import "core:fmt"
import rl "vendor:raylib"

COLS :: 10
ROWS :: 20
CELL_SIZE :: 32

SCREEN_WIDTH :: COLS * CELL_SIZE + (4 * CELL_SIZE + 30)
SCREEN_HEIGHT :: ROWS * CELL_SIZE

colors: [7]rl.Color = {
	{0, 240, 240, 255}, // I
	{240, 240, 0, 255}, // O
	{160, 0, 240, 255}, // T
	{0, 240, 0, 255},   // S
	{240, 0, 0, 255},   // Z
	{0, 0, 240, 255},   // J
	{240, 160, 0, 255}  // L
}

tetrominoes: [7][4][4]u8 = {
	{ // I
		{0, 0, 1, 0},
		{0, 0, 1, 0},
		{0, 0, 1, 0},
		{0, 0, 1, 0}
	},
	{ // O
		{0, 0, 0, 0},
		{0, 1, 1, 0},
		{0, 1, 1, 0},
		{0, 0, 0, 0}
	},
	{ // T
		{0, 1, 0, 0},
		{1, 1, 1, 0},
		{0, 0, 0, 0},
		{0, 0, 0, 0}
	},
	{ // S
		{0, 1, 1, 0},
		{1, 1, 0, 0},
		{0, 0, 0, 0},
		{0, 0, 0, 0}
	},
	{ // Z
		{1, 1, 0, 0},
		{0, 1, 1, 0},
		{0, 0, 0, 0},
		{0, 0, 0, 0}
	},
	{ // J
		{1, 0, 0, 0},
		{1, 1, 1, 0},
		{0, 0, 0, 0},
		{0, 0, 0, 0}
	},
	{ // L
		{0, 0, 1, 0},
		{1, 1, 1, 0},
		{0, 0, 0, 0},
		{0, 0, 0, 0}
	}
}

current_tetromino_idx: u8
current_tetromino: [4][4]u8
next_tetromino_idx: u8
next_tetromino: [4][4]u8
grid: [ROWS][COLS]u8 = 0

can_move :: proc(new_pos: [2]i32, tetromino: [4][4]u8) -> bool {
	for y in 0..<i32(4) {
		dy := new_pos.y + y

		for x in 0..<i32(4) {
			dx := new_pos.x + x

			if tetromino[y][x] == 1 {
				// Vertical Bounds
				if dy >= ROWS do return false

				// Horizontal Bounds
				if (dx < 0 || dx >= COLS) do return false

				// Other Blocks
				else if dy >= 0 do if grid[dy][dx] != 0 do return false
			}
		}
	}

	return true
}

rotate :: proc(pos: [2]i32) -> bool {
	n := (current_tetromino_idx == 0 || current_tetromino_idx == 1) ? 4 : 3
	new_pos: [4][4]u8

	/*                          original       cw-rotation    ccw-rotation
		1 2 3      7 4 1    0,0 1,0 2,0    0,2 0,1 0,0    2,0 2,1 2,2
		4 5 6  ->  8 5 2    0,1 1,1 2,1    1,2 1,1 1,0    1,0 1,1 1,2
		7 8 9      9 6 3    0,2 1,2 2,2    2,2 2,1 2,0    0,0 0,1 0,2
	*/
	
	for i in 0..<n {
		for j in 0..<n {
			// new_pos[n - j - 1][i] = current_tetromino[i][j] // Counter Clockwise Rotation
			new_pos[j][n - i - 1] = current_tetromino[i][j] // Clockwise Rotation
		}
	}

	if can_move(pos, new_pos) {
		current_tetromino = new_pos
		return true
	}

	return false
}

calculate_landing_pos :: proc(curr_pos: [2]i32) -> [2]i32 {
	pos: [2]i32 = {curr_pos.x, curr_pos.y}

	for can_move(pos, current_tetromino) do pos.y += 1
	pos.y -= 1

	return pos
}

main :: proc() {

	start_pos: [2]i32 = {COLS / 2 - 2, -3}
	pos: [2]i32 = start_pos

	time_between_fall: f32 = 0.3
	current_time: f32 = 0

	current_tetromino_idx = u8(rand.int31() % 7)
	current_tetromino = tetrominoes[current_tetromino_idx]
	next_tetromino_idx = u8(rand.int31() % 7)
	next_tetromino = tetrominoes[next_tetromino_idx]

	is_game_over: bool = false
	is_paused: bool = false
	score: i32 = 0

	landing_pos: [2]i32 = calculate_landing_pos(pos)

	rl.SetTraceLogLevel(.ERROR)

	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Tetris")
	defer rl.CloseWindow()

	rl.SetExitKey(.KEY_NULL)
	rl.SetTargetFPS(60)

	for rl.WindowShouldClose() == false {

		if rl.IsKeyPressed(.ESCAPE) && !is_game_over do is_paused = !is_paused

		if !is_game_over && !is_paused {
			current_time += rl.GetFrameTime()

			if (rl.IsKeyDown(.DOWN) || rl.IsKeyDown(.S)) do time_between_fall = 0.3 * 0.2
			else if (rl.IsKeyUp(.DOWN) || rl.IsKeyUp(.S)) do time_between_fall = 0.3

			if rl.IsKeyPressed(.SPACE) {
				pos = landing_pos
				time_between_fall = 0
			}

			if current_time >= time_between_fall { // VERTICAL MOVEMENT
				current_time -= time_between_fall
				time_between_fall = 0.3
				new_pos_y := pos.y + 1

				if can_move({pos.x, new_pos_y}, current_tetromino) {
					pos.y = new_pos_y
				} else {
					// End of Current Tetronimo's journey
					for y in 0..<i32(4) {
						dy := pos.y + y

						// Game over condition
						if dy < 0 {
							is_game_over = true
							is_paused = false
						}

						// Embed into grid
						for x in 0..<i32(4) {
							dx := pos.x + x

							if current_tetromino[y][x] == 1 {
								if dy >= 0 do grid[dy][dx] = current_tetromino_idx + 1
							}
						}
					}

					// Check for clearing
					for y: i32 = ROWS - 1; y >= 0; {
						is_full_row: bool = true
						for x in 0..<COLS {
							if grid[y][x] == 0 do is_full_row = false
						}

						// Move all things down
						if is_full_row {

							score += 1

							for j: i32 = y; j > 0; j -= 1{
								for x in 0..<COLS {
									grid[j][x] = grid[j - 1][x]
								}
							}
						} else {
							y -= 1
						}
					}

					// Change Tetronimo
					current_tetromino = next_tetromino
					current_tetromino_idx = next_tetromino_idx
					next_tetromino_idx = u8(rand.int31() % 7)
					next_tetromino = tetrominoes[next_tetromino_idx]
					pos = start_pos

					landing_pos = calculate_landing_pos(pos)
				}
			}

			{ // HORIZONTAL MOVEMENT
				new_pos_x: i32 = -COLS
				if rl.IsKeyPressed(.A) || rl.IsKeyPressed(.LEFT)  do new_pos_x = pos.x - 1
				if rl.IsKeyPressed(.D) || rl.IsKeyPressed(.RIGHT) do new_pos_x = pos.x + 1

				if can_move({new_pos_x, pos.y}, current_tetromino) && new_pos_x != -COLS {
					pos.x = new_pos_x
					landing_pos = calculate_landing_pos(pos)
				}
			}

			{ // ROTATION
				if rl.IsKeyPressed(.W) || rl.IsKeyPressed(.UP) {
					has_rotated: bool = rotate(pos)

					if has_rotated {
						landing_pos = calculate_landing_pos(pos)
					}
				}
			}
		} else { // if is_game_over
			if rl.IsKeyPressed(.SPACE) && is_game_over {
				grid = 0

				current_tetromino_idx = u8(rand.int31() % 7)
				current_tetromino = tetrominoes[current_tetromino_idx]
				next_tetromino_idx = u8(rand.int31() % 7)
				next_tetromino = tetrominoes[next_tetromino_idx]

				landing_pos = calculate_landing_pos(pos)

				is_game_over = false
				score = 0
			}
		}

		rl.BeginDrawing()
		rl.ClearBackground(rl.RAYWHITE)

		// Grid Lines
		for x in 0..<COLS+1 do rl.DrawLineV({f32(x * CELL_SIZE), 0}, {f32(x * CELL_SIZE), ROWS * CELL_SIZE}, rl.LIGHTGRAY)
		for y in 0..<ROWS do rl.DrawLineV({0, f32(y * CELL_SIZE)}, {COLS * CELL_SIZE, f32(y * CELL_SIZE)}, rl.LIGHTGRAY)

		// Tetromino
		for y in 0..<i32(4) {
			cy := (y + pos.y) * i32(CELL_SIZE)
			ny := y * i32(CELL_SIZE) + 30
			ly := (y + landing_pos.y) * i32(CELL_SIZE)

			for x in 0..<i32(4) {
				cx := (x + pos.x) * i32(CELL_SIZE)
				nx := (x + COLS) * i32(CELL_SIZE) + 30
				lx := (x + landing_pos.x) * i32(CELL_SIZE)

				// Current Tetromino
				if current_tetromino[y][x] == 1 {
					color: rl.Color = is_game_over ? rl.LIGHTGRAY : colors[current_tetromino_idx]
					rl.DrawRectangle(cx, cy, CELL_SIZE, CELL_SIZE, color)
					rl.DrawRectangleLines(cx, cy, CELL_SIZE, CELL_SIZE, rl.BLACK)

					// Landing Position
					color.a = 80
					rl.DrawRectangle(lx, ly, CELL_SIZE, CELL_SIZE, color)
				}

				// Next Tetromino
				if next_tetromino[y][x] == 1 {
					rl.DrawRectangle(nx, ny, CELL_SIZE, CELL_SIZE, colors[next_tetromino_idx])
					rl.DrawRectangleLines(nx, ny, CELL_SIZE, CELL_SIZE, rl.BLACK)
				}
			}
		}

		// Grid
		for y in 0..<i32(ROWS) {
			dy := y * CELL_SIZE
			for x in 0..<i32(COLS) {
				dx := x * CELL_SIZE

				if grid[y][x] != 0 {
					color: rl.Color = is_game_over ? rl.LIGHTGRAY : colors[grid[y][x] - 1]
					rl.DrawRectangle(dx, dy, CELL_SIZE, CELL_SIZE, color)
					rl.DrawRectangleLines(dx, dy, CELL_SIZE, CELL_SIZE, rl.BLACK)
				}
			}
		}

		// rl.DrawRectangleLines(pos.x * CELL_SIZE, pos.y * CELL_SIZE, 4 * CELL_SIZE, 4 * CELL_SIZE, rl.BLACK)

		{ // Score
			text: cstring = fmt.caprint("Score:", score)
			font_size: i32 = 24
			width: i32 = rl.MeasureText(text, font_size)

			x: i32 = i32(COLS * CELL_SIZE) + 30
			y: i32 = i32(ROWS * CELL_SIZE) - 60

			rl.DrawText(text, x, y, font_size, rl.BLACK)
		}

		// Game Over
		if is_game_over {
			rl.DrawRectangle(
				SCREEN_WIDTH/2 - 150,
				SCREEN_HEIGHT/2 - 100,
				300, 200,
				rl.GRAY)

			text: cstring = "Game Over"
			font_size: i32 = 32
			width: i32 = rl.MeasureText(text, font_size)

			x: i32 = (SCREEN_WIDTH - width) / 2
			y: i32 = (SCREEN_HEIGHT - font_size) / 2 - 20

			rl.DrawText(text, x, y, font_size, rl.WHITE)

			text = "<SPACE> to restart"
			font_size = 24
			width = rl.MeasureText(text, font_size)

			x = (SCREEN_WIDTH - width) / 2
			y = (SCREEN_HEIGHT - font_size) / 2 + 20

			rl.DrawText(text, x, y, font_size, rl.LIGHTGRAY)
		}

		// Paused
		if is_paused {
			rl.DrawRectangle(
				SCREEN_WIDTH/2 - 150,
				SCREEN_HEIGHT/2 - 100,
				300, 200,
				rl.GRAY)

			text: cstring = "Game Paused"
			font_size: i32 = 32
			width: i32 = rl.MeasureText(text, font_size)

			x: i32 = (SCREEN_WIDTH - width) / 2
			y: i32 = (SCREEN_HEIGHT - font_size) / 2 - 20

			rl.DrawText(text, x, y, font_size, rl.WHITE)

			text = "<ESC> to resume"
			font_size = 24
			width = rl.MeasureText(text, font_size)

			x = (SCREEN_WIDTH - width) / 2
			y = (SCREEN_HEIGHT - font_size) / 2 + 20

			rl.DrawText(text, x, y, font_size, rl.LIGHTGRAY)
		}


		rl.EndDrawing()
	}
}