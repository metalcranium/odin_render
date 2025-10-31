#version 330 core
layout (location = 0) in vec3 position;

uniform mat4 transform;
uniform mat4 projection;
out vec4 vertexColor;

void main(){
    gl_Position = projection * transform * vec4(position, 1.0);
    vertexColor = vec4(1.0, 1.0, 0.0, 1.0);
}
