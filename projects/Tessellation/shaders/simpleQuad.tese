#version 410

layout(quads, fractional_odd_spacing, ccw) in;

uniform	mat4 projViewModelMatrix;

in vec4 posTC[];

void main() {

	float u = gl_TessCoord.x;
	float v = gl_TessCoord.y;
	float w = 1 - u - v;
	
	vec4 p1 = mix(posTC[0],posTC[1],u);
	vec4 p2 = mix(posTC[3],posTC[2],u);
	gl_Position = projViewModelMatrix * mix(p1, p2, v);
}

