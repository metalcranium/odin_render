package main

import "core:fmt"
import glm "core:math/linalg/glsl"
import "core:time"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"
import stbi "vendor:stb/image"

Game :: proc(window: glfw.WindowHandle) {
	// color_vs_source := cstring(#load("vertex_shader.glsl"))
	// color_fs_source := cstring(#load("fragment_shader.glsl"))
	color_vs_source := cstring(#load("test_vs.glsl"))
	color_fs_source := cstring(#load("test_fs.glsl"))
	texture_vs_source := cstring(#load("vertex_texture_shader.glsl"))
	texture_fs_source := cstring(#load("fragment_texture_shader.glsl"))
	texture_shader := CompileShader(texture_vs_source, texture_fs_source)
	color_shader := CompileShader(color_vs_source, color_fs_source)
	defer CleanupShader(texture_shader)
	defer CleanupShader(color_shader)

	path := cstring("./herowalk.png")
	tex := LoadTexture(path)
	defer stbi.image_free(tex.data)
	defer free(tex)

	path = cstring("./container.jpg")
	tex1 := LoadTexture(path)
	defer stbi.image_free(tex1.data)
	defer free(tex1)

	path = cstring("./wall.jpg")
	tex2 := LoadTexture(path)
	defer stbi.image_free(tex2.data)
	defer free(tex2)

	fmt.println(tex.height)
	fmt.println(tex.width)
	player: Object = {
		x           = 500,
		y           = 500,
		width       = 64,
		height      = 64,
		direction   = {0, -1},
		speed       = 10,
		jump        = 50,
		is_grounded = false,
		is_blocked  = false,
	}
	player.rec = {player.x, player.y, player.width, player.height}
	rec: Rectangle = {
		x      = 500,
		y      = 0,
		width  = 64,
		height = 64,
	}
	player.source = {
		x      = 0,
		y      = 0,
		width  = 32,
		height = 32,
	}
	source: Rectangle = {
		x      = 0,
		y      = 0,
		width  = f32(tex1.width),
		height = f32(tex1.height),
	}
	background: Rectangle = {
		x      = 0,
		y      = 0,
		width  = SCR_WIDTH,
		height = SCR_HEIGHT,
	}
	bg_source: Rectangle = {
		x      = 0,
		y      = 0,
		width  = f32(tex2.width),
		height = f32(tex2.height),
	}
	frame: Frame

	delta_time := GetDeltaTime(FPS)

	animate: FrameCounter
	animate.frames = 6
	animate.frame_speed = 5

	for !glfw.WindowShouldClose(window) {

		time.sleep(16000000) // milliseconds with 6 zeros
		CalculateDeltaTime(&frame, &delta_time)
		// GetFPS(delta_time)
		animate.frame_counter += 1
		if animate.frame_counter >= 60 / animate.frame_speed {
			animate.frame_counter = 0
			animate.frame += 1
			player.source.x += 1
			if u32(player.source.x) > animate.frames {
				player.source.x = 1
			}
			if animate.frame >= animate.frames {
				animate.frame = 0
			}
		}

		collided := CheckCollisionRec(player.rec, rec)
		if collided {
			ResolveCollisionRec(&player, rec)
			player.x = player.rec.x
			player.y = player.rec.y
		}

		UpdatePlayer(window, &player, delta_time)
		ProcessInput(window)

		// this acts as a sudo camera view
		projection := glm.mat4Ortho3d(
			player.x - 300,
			player.x + 300,
			player.y - 300,
			player.y + 300,
			-1,
			1,
		)

		// projection += view
		ClearScreen(GRAY)

		DrawTexture(texture_shader.program, player.source, player.rec, tex, &projection)
		// DrawRectangle(color_shader.program, player.rec, YELLOW)
		DrawRectangle(color_shader.program, rec, YELLOW, &projection)
		// DrawTexture(texture_shader.program, source, &rec, tex1)
		if collided {
			DrawRectangle(color_shader.program, GetCollisionRec(player.rec, rec), RED, &projection)
		}
		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}

}
