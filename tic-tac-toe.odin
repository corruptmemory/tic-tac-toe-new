package main

import "core:log"
import "vendor:raylib"
import "core:math"

screen_width :: 1920
screen_height :: 1080
move_per_second : f32 : 1.0
target_fps :: 60

approach :: proc(t: f32) -> f32 {
	p := f32(math.lerp(f32(-9.0), f32(5.0), t))
	return (-p + 5.0)/(p + 10.0)
}

main :: proc() {
	context.logger = log.create_console_logger()
	log.debug("Hello from tic-tac-toe")
	raylib.InitWindow(screen_width, screen_height, "Bouncy text!")
	raylib.SetTargetFPS(target_fps)

    camera := raylib.Camera{ { 0.0, 0.0, 0.25 }, { 0.0, 0.0, 0.0 }, { 0.0, 1.0, 0.0 }, 45.0, raylib.CameraProjection.PERSPECTIVE }
	position := raylib.Vector3{ 0.0, 0.0, 0.0 }

	model := raylib.LoadModel("board.obj");
	target := raylib.LoadRenderTexture(screen_width, screen_height)

	param : f32 = 0.0
	animating := false

	for !raylib.WindowShouldClose() {
		if raylib.IsKeyPressed(raylib.KeyboardKey.ENTER) {
			animating = true
			param = 0.0
		}
		if animating {
			param = min(param + raylib.GetFrameTime()*move_per_second, 1.0)
			if param == 1.0 {
				animating = false
			}
			position[2] = approach(param)
			// position[1] = approach(param)
			// position[0] = approach(param)
		}
		raylib.BeginTextureMode(target)       // Enable drawing to texture
			raylib.ClearBackground(raylib.RAYWHITE)  // Clear texture background
			raylib.BeginMode3D(camera)        // Begin 3d mode drawing
				raylib.DrawModel(model, position, 0.1, raylib.RED)   // Draw 3d model with texture
				raylib.DrawGrid(10, 1.0)      // Draw a grid
			raylib.EndMode3D()                // End 3d mode drawing, returns to orthographic 2d mode
		raylib.EndTextureMode()               // End drawing to texture (now we have a texture available for next passes)

		raylib.BeginDrawing()
			raylib.ClearBackground(raylib.RAYWHITE)
			raylib.DrawTextureRec(target.texture, raylib.Rectangle{ 0, 0, f32(target.texture.width), f32(-target.texture.height)}, raylib.Vector2{ 0, 0 }, raylib.WHITE)
		raylib.EndDrawing()
	}
	raylib.UnloadRenderTexture(target)
	raylib.UnloadModel(model)
	raylib.CloseWindow()
}