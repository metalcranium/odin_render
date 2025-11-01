package main

import "core:fmt"
import glm "core:math/linalg/glsl"
import gl "vendor:OpenGL"
import "vendor:glfw"
import stbi "vendor:stb/image"

SCR_WIDTH :: 1200
SCR_HEIGHT :: 800
GRAVITY :: 5

Vec2 :: struct {
	x, y: f32,
}
Rectangle :: struct {
	x, y, width, height: f32,
}
Object :: struct {
	rec:         Rectangle,
	x:           f32,
	y:           f32,
	width:       f32,
	height:      f32,
	direction:   Vec2,
	speed:       f32,
	jump:        f32,
	is_grounded: bool,
	is_blocked:  bool,
	source:      Rectangle,
}
Color :: struct {
	red:   f32,
	green: f32,
	blue:  f32,
	alpha: f32,
}
Frame :: struct {
	frames:        f32,
	last_frame:    f64,
	current_frame: f64,
}
Texture :: struct {
	width, height, nrChannels: i32,
	filepath:                  cstring,
	data:                      [^]u8,
	texture:                   u32,
}
RED :: Color{1.0, 0.0, 0.0, 1.0}
GREEN :: Color{0.0, 1.0, 0.0, 1.0}
BLUE :: Color{0.0, 0.0, 1.0, 1.0}
CYAN :: Color{0.0, 1.0, 1.0, 1.0}
TEAL :: Color{0.0, 0.3, 0.3, 1.0}
YELLOW :: Color{1.0, 1.0, 0.0, 1.0}
PURPLE :: Color{1.0, 0.0, 1.0, 1.0}
GRAY :: Color{0.5, 0.5, 0.5, 1.0}
DARKGRAY :: Color{0.3, 0.3, 0.3, 1.0}
CHARCOALGRAY :: Color{0.2, 0.2, 0.2, 1.0}
WHITE :: Color{1.0, 1.0, 1.0, 1.0}

main :: proc() {
	fmt.println("this sucks")
	window := CreateWindow(SCR_WIDTH, SCR_HEIGHT, "Odin OpenGL")
	defer glfw.DestroyWindow(window)
	defer glfw.Terminate()

	// vs_source := cstring(#load("vertex_shader.glsl"))
	// fs_source := cstring(#load("fragment_shader.glsl"))
	// vs_source := cstring(#load("test_vs.glsl"))
	// fs_source := cstring(#load("test_fs.glsl"))
	vs_source := cstring(#load("vertex_texture_shader.glsl"))
	fs_source := cstring(#load("fragment_texture_shader.glsl"))
	shader := CompileShader(vs_source, fs_source)
	defer CleanupShader(shader)

	stbi.set_flip_vertically_on_load(1)
	tex := LoadTexture("./herowalk.png")

	gl.GenTextures(1, &tex.texture)
	gl.BindTexture(gl.TEXTURE_2D, tex.texture)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
	// width, height, nrChannels: i32
	// filepath: cstring = "./awesomeface.png"
	// data: [^]u8 = stbi.load(filepath, &width, &height, &nrChannels, 0)

	if tex.data != nil {
		gl.TexImage2D(
			gl.TEXTURE_2D,
			0,
			gl.RGB,
			tex.width,
			tex.height,
			0,
			gl.RGBA,
			gl.UNSIGNED_BYTE,
			tex.data,
		)
		gl.GenerateMipmap(gl.TEXTURE_2D)
	} else {
		fmt.println("yyou suck big time")
	}
	defer stbi.image_free(tex.data)
	defer free(tex)

	projection := glm.mat4Ortho3d(0, SCR_WIDTH, 0, SCR_HEIGHT, -1, 1)

	fmt.println(tex.height)
	fmt.println(tex.width)
	player: Object = {
		x           = 500,
		y           = 500,
		width       = 100,
		height      = 100,
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
	source: Rectangle = {
		x      = 1,
		y      = 0,
		width  = 32,
		height = 32,
	}

	delta_time: f32 = GetDeltaTime(60)

	for !glfw.WindowShouldClose(window) {
		collided := CheckCollisionRec(player.rec, rec)
		if collided {
			// fmt.println("collision")
			ResolveCollisionRec(&player, rec)
			player.x = player.rec.x
			player.y = player.rec.y
		}
		// fmt.println("has collided", collided)

		UpdatePlayer(window, &player, delta_time)
		ProcessInput(window)
		gl.ClearColor(0.3, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		projectionloc := gl.GetUniformLocation(shader.program, "projection")
		gl.UniformMatrix4fv(projectionloc, 1, gl.FALSE, &projection[0][0])

		gl.UseProgram(shader.program)

		// DrawTriangle(shader.program, TEAL)
		// DrawRectangle(shader.program, 100, 0, 32, 32, CYAN)
		DrawRectangle(shader.program, rec, YELLOW)
		// DrawRectangle(shader.program, player.rec, TEAL)
		DrawTexture(shader.program, source, &player.rec, tex)
		if collided {
			DrawRectangle(shader.program, GetCollisionRec(player.rec, rec), RED)
		}

		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}
}

Shader :: struct {
	vertex_shader_source:   cstring,
	fragment_shader_source: cstring,
	vertex_shader:          u32,
	fragment_shader:        u32,
	program:                u32,
}
CreateWindow :: proc(width: i32, height: i32, title: cstring) -> glfw.WindowHandle {
	glfw.Init()
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	window := glfw.CreateWindow(width, height, title, nil, nil)
	glfw.MakeContextCurrent(window)
	gl.load_up_to(3, 3, glfw.gl_set_proc_address)
	glfw.SetFramebufferSizeCallback(window, framebuffer_size_callback)
	// gl.Viewport(0, 0, SCR_WIDTH, SCR_HEIGHT)

	return window
}
framebuffer_size_callback :: proc "c" (window: glfw.WindowHandle, width: i32, height: i32) {
	gl.Viewport(0, 0, width, height)
}

ProcessInput :: proc(window: glfw.WindowHandle) {
	if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
		glfw.SetWindowShouldClose(window, true)
	}
}
Update :: proc(window: glfw.WindowHandle) {
	ProcessInput(window)
}
Draw :: proc(window: glfw.WindowHandle) {
	// DrawTriangle(shader_program)
	glfw.SwapBuffers(window)
	glfw.PollEvents()

}
CompileShader :: proc(vs_source: cstring, fs_source: cstring) -> ^Shader {
	shader := new(Shader)
	shader.vertex_shader_source = vs_source
	shader.fragment_shader_source = fs_source

	shader.vertex_shader = gl.CreateShader(gl.VERTEX_SHADER)
	gl.ShaderSource(shader.vertex_shader, 1, &shader.vertex_shader_source, nil)
	gl.CompileShader(shader.vertex_shader)
	success: i32
	infoLog: [^]u8
	gl.GetShaderiv(shader.vertex_shader, gl.COMPILE_STATUS, &success)
	if success == 0 {
		fmt.println("vertex shader failed")
	} else {
		fmt.println("vertex shader success")
	}

	shader.fragment_shader = gl.CreateShader(gl.FRAGMENT_SHADER)
	gl.ShaderSource(shader.fragment_shader, 1, &shader.fragment_shader_source, nil)
	gl.CompileShader(shader.fragment_shader)
	gl.GetShaderiv(shader.fragment_shader, gl.COMPILE_STATUS, &success)
	if success == 0 {
		fmt.println("fragment shader failed")
	} else {
		fmt.println("fragment shader success")
	}

	shader.program = gl.CreateProgram()
	gl.AttachShader(shader.program, shader.vertex_shader)
	gl.AttachShader(shader.program, shader.fragment_shader)
	gl.LinkProgram(shader.program)
	gl.GetProgramiv(shader.program, gl.LINK_STATUS, &success)
	if success == 0 {
		fmt.println("shader program failed")
	} else {
		fmt.println("shader program success")
	}
	fmt.println("shader successfully compiled")
	return shader
}
CleanupShader :: proc(shader: ^Shader) {
	gl.DeleteShader(shader.vertex_shader)
	gl.DeleteShader(shader.fragment_shader)
	gl.DeleteProgram(shader.program)
	free(shader)
	fmt.println("shader successfully cleaned up")
}
// TODO implement cleanup for buffers
CreateBuffer :: proc(vertices: []f32, indices: []i32) -> u32 {
	vbo, vao, ebo: u32

	gl.GenVertexArrays(1, &vao)
	gl.BindVertexArray(vao)

	gl.GenBuffers(1, &vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		size_of(f32) * len(vertices),
		raw_data(vertices),
		gl.STATIC_DRAW,
	)
	if indices != nil {
		gl.GenBuffers(1, &ebo)
		gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
		gl.BufferData(
			gl.ELEMENT_ARRAY_BUFFER,
			size_of(i32) * len(indices),
			raw_data(indices),
			gl.STATIC_DRAW,
		)
	}
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), cast(uintptr)0)
	gl.EnableVertexAttribArray(0)

	return vao
}
CreateTextureBuffer :: proc(vertices: []f32, indices: []u32) -> u32 {

	vbo, vao, ebo: u32
	gl.GenVertexArrays(1, &vao)
	gl.BindVertexArray(vao)
	// defer gl.DeleteVertexArrays(1, &vao)

	gl.GenBuffers(1, &vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	// defer gl.DeleteBuffers(1, &vbo)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		size_of(f32) * len(vertices),
		raw_data(vertices),
		gl.STATIC_DRAW,
	)

	gl.GenBuffers(1, &ebo)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	// defer gl.DeleteBuffers(1, &ebo)
	gl.BufferData(
		gl.ELEMENT_ARRAY_BUFFER,
		size_of(u32) * len(indices),
		raw_data(indices),
		gl.STATIC_DRAW,
	)

	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 8 * size_of(f32), cast(uintptr)0)
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(
		1,
		3,
		gl.FLOAT,
		gl.FALSE,
		8 * size_of(f32),
		cast(uintptr)(3 * size_of(f32)),
	)
	gl.EnableVertexAttribArray(1)
	gl.VertexAttribPointer(
		2,
		2,
		gl.FLOAT,
		gl.FALSE,
		8 * size_of(f32),
		cast(uintptr)(6 * size_of(f32)),
	)
	gl.EnableVertexAttribArray(2)
	return vao
}
DrawTriangle :: proc(shaderProgram: u32, color: Color) {
	vertices: []f32 = {-1.0, -1.0, 0.0, 0.0, 0.0, 0.0, 1.0, -1.0, 0.0} //{-0.5, -0.5, 0.0, 0.5, -0.5, 0.0, 0.0, 0.5, 0.0}
	vao := CreateBuffer(vertices, nil)
	defer gl.DeleteVertexArrays(1, &vao)

	trans := glm.mat4(1.0)
	trans = glm.mat4Translate({1.0, 1.0, 0.0})
	// trans = glm.mat4Rotate({0.0, 0.0, 1.0}, f32(glfw.GetTime()))

	gl.UseProgram(shaderProgram)

	transformloc := gl.GetUniformLocation(shaderProgram, "transform")
	gl.UniformMatrix4fv(transformloc, 1, gl.FALSE, &trans[0][0])
	vertexColorLocation := gl.GetUniformLocation(shaderProgram, "ourColor")
	gl.Uniform4f(vertexColorLocation, color.red, color.green, color.blue, color.alpha)

	gl.BindVertexArray(vao)
	gl.DrawArrays(gl.TRIANGLES, 0, 3)

}
DrawRectangle :: proc(shaderProgram: u32, rec: Rectangle, color: Color) {
	// vertices: []f32 = {-0.5, -0.5, 0.0, -0.5, 0.5, 0.0, 0.5, 0.5, 0.0, 0.5, -0.5, 0.0}
	vertices: []f32 = {
		rec.x,
		rec.y,
		0.0,
		rec.x,
		rec.y + rec.height,
		0.0,
		rec.x + rec.width,
		rec.y + rec.height,
		0.0,
		rec.x + rec.width,
		rec.y,
		0.0,
	}
	indices: []i32 = {0, 1, 3, 1, 2, 3}

	vao := CreateBuffer(vertices, indices)
	defer gl.DeleteVertexArrays(1, &vao)

	trans := glm.mat4(1.0)
	trans = glm.mat4Translate({1.0, 1.0, 0.0})
	// trans += glm.mat4(1)
	// trans = glm.mat4Rotate({0.0, 0.0, 1.0}, f32(glfw.GetTime()))

	gl.UseProgram(shaderProgram)

	transformloc := gl.GetUniformLocation(shaderProgram, "transform")
	gl.UniformMatrix4fv(transformloc, 1, gl.FALSE, &trans[0][0])
	vertexColorLocation := gl.GetUniformLocation(shaderProgram, "ourColor")
	gl.Uniform4f(vertexColorLocation, color.red, color.green, color.blue, color.alpha)

	gl.BindVertexArray(vao)
	gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)
	gl.BindVertexArray(0)
}
// TODO complete the source vertices
DrawTexture :: proc(shader_program: u32, source: Rectangle, rec: ^Rectangle, tex: ^Texture) {
	src: Rectangle = {
		x      = source.x * (source.width / f32(tex.width)),
		y      = source.y * (source.height / f32(tex.height)),
		width  = source.width / f32(tex.width),
		height = source.height / f32(tex.height),
	}
	vertices: []f32 = {
		rec.x, //
		rec.y,
		0.0,
		1.0,
		0.0,
		0.0,
		src.x,
		src.y,
		rec.x, //
		rec.y + rec.height,
		0.0,
		0.0,
		1.0,
		0.0,
		src.x,
		src.y + src.height,
		rec.x + rec.width, //
		rec.y + rec.height,
		0.0,
		0.0,
		0.0,
		1.0,
		src.x + src.width,
		src.y + src.height,
		rec.x + rec.width, //
		rec.y,
		0.0,
		1.0,
		1.0,
		0.0,
		src.x + src.width,
		src.y,
	}
	indices: []u32 = {0, 1, 3, 1, 2, 3}
	vao := CreateTextureBuffer(vertices, indices)
	defer gl.DeleteVertexArrays(1, &vao)
	// texture: u32
	// gl.GenTextures(1, &texture)
	// gl.BindTexture(gl.TEXTURE_2D, texture)

	// gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	// gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
	// gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
	// gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
	// // width, height, nrChannels: i32
	// // filepath: cstring = "./awesomeface.png"
	// // data: [^]u8 = stbi.load(filepath, &width, &height, &nrChannels, 0)
	// if tex.data != nil {
	// 	gl.TexImage2D(
	// 		gl.TEXTURE_2D,
	// 		0,
	// 		gl.RGB,
	// 		tex.width,
	// 		tex.height,
	// 		0,
	// 		gl.RGBA,
	// 		gl.UNSIGNED_BYTE,
	// 		tex.data,
	// 	)
	// 	gl.GenerateMipmap(gl.TEXTURE_2D)
	// } else {
	// 	fmt.println("yyou suck big time")
	// }
	// // defer stbi.image_free(data)
	trans := glm.mat4(1)
	trans = glm.mat4Translate({1.0, 1.0, 0.0})

	gl.UseProgram(shader_program)

	transformloc := gl.GetUniformLocation(shader_program, "transform")
	gl.UniformMatrix4fv(transformloc, 1, gl.FALSE, &trans[0][0])

	gl.BindTexture(gl.TEXTURE_2D, tex.texture)
	gl.BindVertexArray(vao)
	gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)
}
UpdatePlayer :: proc(window: glfw.WindowHandle, player: ^Object, delta_time: f32) {
	player.x += player.speed * player.direction.x
	player.y += GRAVITY * player.direction.y

	player.rec = {player.x, player.y, player.width, player.height}
	if player.x + player.width > SCR_WIDTH {
		player.x -= player.speed * player.direction.x
		player.direction.x *= -1 * 0.2
		player.is_blocked = true
	} else if player.x < 0 {
		player.x -= player.speed * player.direction.x
		player.direction.x *= -1 * 0.2
		player.is_blocked = true
	}
	if glfw.GetKey(window, glfw.KEY_RIGHT) == glfw.PRESS && player.is_blocked == false {
		player.direction.x += 1 * delta_time
		if player.direction.x > 1 {
			player.direction.x = 1
		}
	} else if glfw.GetKey(window, glfw.KEY_LEFT) == glfw.PRESS && player.is_blocked == false {
		player.direction.x += -1 * delta_time
		if player.direction.x < -1 {
			player.direction.x = -1
		}
	} else {
		player.direction.x -= player.direction.x * delta_time
	}
	if glfw.GetKey(window, glfw.KEY_UP) == glfw.PRESS && player.is_grounded == true {
		player.is_grounded = false
		player.direction.y += player.jump * delta_time
	} else {
	}
	if player.y < 0 {
		player.is_grounded = true
		player.is_blocked = false
		player.y += 0 - player.y
	} else {
		player.is_grounded = false
	}
	if !player.is_grounded {
		player.direction.y -= 1 * delta_time
	} else {
		player.direction.y = 0
	}
}
GetMousePosition :: proc(window: glfw.WindowHandle) -> Vec2 {
	posx, posy := glfw.GetCursorPos(window)
	mouse_pos := Vec2{f32(posx), SCR_HEIGHT - f32(posy)}
	return mouse_pos
}
GetDeltaTime :: proc(target_fps: f32) -> f32 {
	delta_time := 1000.0 / target_fps / 1000.0
	return delta_time
}
GetFPS :: proc() {

}
// TODO create frame struct
CalculateDeltaTime :: proc(frame: ^Frame) {
	delta_time: f32
	frame.frames += 1
	frame.current_frame = glfw.GetTime()
	// frame.frame_delta = frame.current_frame - frame.last_frame
	if frame.current_frame - frame.last_frame >= 1 {
		delta_time = 1000 / frame.frames / 1000
		// if delta_time < 0.01666 {
		// 	delta_time = 0.01666
		// }
		fmt.println(f32(delta_time))
		frame.frames = 0
		frame.last_frame += 1
	}
}
LoadTexture :: proc(filepath: cstring) -> ^Texture {
	texture := new(Texture)
	texture.filepath = cstring(filepath)

	texture.data = stbi.load(
		texture.filepath,
		&texture.width,
		&texture.height,
		&texture.nrChannels,
		0,
	)
	return texture
}
CheckCollisionRec :: proc(rec1, rec2: Rectangle) -> bool {
	has_collided: bool
	if rec1.x < rec2.x + rec2.width &&
	   rec1.x + rec1.width > rec2.x &&
	   rec1.y < rec2.y + rec2.height &&
	   rec1.y + rec1.height > rec2.y {
		has_collided = true
	} else {
		has_collided = false
	}
	return has_collided
}
GetCollisionRec :: proc(rec1, rec2: Rectangle) -> Rectangle {
	collision: Rectangle
	if rec1.x < rec2.x {
		collision.x = rec2.x
		collision.width = (rec1.x + rec1.width) - rec2.x
		if collision.width > rec2.width {
			collision.width = rec2.width
		}
	} else {
		collision.x = rec2.x + (rec1.x - rec2.x)
		collision.width = (rec2.x + rec2.width) - rec1.x
	}
	if rec1.y > rec2.y {
		collision.y = rec1.y
		collision.height = (rec2.y + rec2.height) - rec1.y

	} else {
		collision.y = rec2.y
		collision.height = (rec1.y + rec1.height) - rec2.y
		if collision.height > rec2.height {
			collision.height = rec2.height
		}
	}
	return collision
}
ResolveCollisionRec :: proc(rec1: ^Object, rec2: Rectangle) {
	sign: Vec2
	collision := GetCollisionRec(rec1.rec, rec2)
	sign.x = rec1.rec.x + rec1.rec.width < rec2.x + rec2.width ? -1 : 1
	sign.y = rec1.rec.y + rec1.rec.height < rec2.y + rec2.height ? -1 : 1
	if collision.width < collision.height {
		rec1.rec.x += collision.width * sign.x
		rec1.direction.x *= -1 * 0.2
	} else if collision.height < collision.width {
		rec1.rec.y += collision.height * sign.y
		rec1.direction.y = 0
		rec1.is_grounded = true
	} else {
		rec1.is_grounded = false
	}
}
