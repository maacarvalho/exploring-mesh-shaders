#version 410

layout(vertices = 16) out;

in vec4 posV[];
out vec4 posTC[];

uniform float olevel = 8.0, ilevel= 8.0;

void main() {

	posTC[gl_InvocationID] = gl_in[gl_InvocationID].gl_Position;
	
	if (gl_InvocationID == 0) {
		gl_TessLevelOuter[0] = olevel;
		gl_TessLevelOuter[1] = olevel;
		gl_TessLevelOuter[2] = olevel;
		gl_TessLevelOuter[3] = olevel;
		gl_TessLevelInner[0] = ilevel;
		gl_TessLevelInner[1] = ilevel;
	}
}