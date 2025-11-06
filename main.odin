package main

import "core:fmt"
import "vendor:glfw"

main :: proc() {
	fmt.println("this sucks")
	window := CreateWindow(SCR_WIDTH, SCR_HEIGHT, "Odin OpenGL")
	defer glfw.DestroyWindow(window)
	defer glfw.Terminate()
	Game(window)
}
