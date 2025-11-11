package main

import "core:fmt"
import gl "vendor:OpenGL"
import "vendor:glfw"

main :: proc() {
	fmt.println("this sucks")
	window := CreateWindow(SCR_WIDTH, SCR_HEIGHT, "Odin OpenGL")
	defer glfw.DestroyWindow(window)
	defer glfw.Terminate()
	Game(window)
	// if !bool(glfw.Init()) {
	// 	fmt.println("glfw failed to load")
	// 	return
	// }
	// glfw.Init()
	// window := glfw.CreateWindow(1200, 800, "odin", nil, nil)
	// defer glfw.Terminate()
	// defer glfw.DestroyWindow(window)

	// glfw.MakeContextCurrent(window)
	// gl.load_up_to(3, 3, glfw.gl_set_proc_address)

	// for !glfw.WindowShouldClose(window) {
	// 	glfw.PollEvents()
	// 	gl.ClearColor(0, 0.3, 0.3, 1.0)
	// 	gl.Clear(gl.COLOR_BUFFER_BIT)
	// 	glfw.SwapBuffers(window)
	// }
	// Game(window)
}
