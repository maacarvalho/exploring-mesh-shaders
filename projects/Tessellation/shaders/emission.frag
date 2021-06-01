#version 410

uniform	mat4 viewMatrix;
uniform vec4 lightDir;
uniform vec4 diffuse;

in vec3 normalTE;

out vec4 outputF;

void main() {

	outputF = vec4(0,1,0,0);
}