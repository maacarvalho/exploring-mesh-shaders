#version 430

uniform sampler2D tex;

in vec2 texCoord;

out vec4 c;

void main() {

	c = texture(tex,texCoord);
}