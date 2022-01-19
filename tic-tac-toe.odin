package main

import "core:log"
import "vendor:raylib"

screen_width :: 1920
screen_height :: 1080
move_per_second : f32 : 180.0
target_fps :: 60

main :: proc() {
	context.logger = log.create_console_logger()
	log.debug("Hello from tic-tac-toe")
	raylib.InitWindow(screen_width, screen_height, "Bouncy text!")
	raylib.SetTargetFPS(target_fps)

    camera := raylib.Camera{ { 0.0, 0.0, 0.25 }, { 0.0, 0.0, 0.0 }, { 0.0, 1.0, 0.0 }, 45.0, raylib.CameraProjection.PERSPECTIVE }
	position := raylib.Vector3{ 0.0, 0.0, 0.0 }

	model := raylib.LoadModel("board.obj");
	target := raylib.LoadRenderTexture(screen_width, screen_height)

	for !raylib.WindowShouldClose() {
		raylib.BeginTextureMode(target)       // Enable drawing to texture
			raylib.ClearBackground(raylib.RAYWHITE)  // Clear texture background
			raylib.BeginMode3D(camera)        // Begin 3d mode drawing
				raylib.DrawModel(model, position, 0.1, raylib.WHITE)   // Draw 3d model with texture
				raylib.DrawGrid(10, 1.0)     // Draw a grid
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