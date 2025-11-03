#version 330 core
// out vec4 color;
out vec4 FragColor;

in vec3 ourColor;
in vec2 TexCoord;

uniform sampler2D ourTexture;
uniform vec4 color;

void main(){
    FragColor = texture2D(ourTexture, TexCoord);
    if(FragColor.a < 0.1)
        discard;
    // vec4 color = texture2D(ourTexture, TexCoord); if (color.w < 1) gl_FragColor = vec4(1,0,0,1); else gl_FragColor = vec4(0,1,0,1);
    // FragColor = texture(ourTexture, TexCoord) * vec4(ourColor, 1.0);
}
