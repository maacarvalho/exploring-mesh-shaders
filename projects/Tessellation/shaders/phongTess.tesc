#version 410

layout(vertices = 3) out;

in vec4 posV[];
in vec4 normalV[];

out vec4 posTC[];
out vec4 normalTC[];

uniform float olevel=1;
uniform float ilevel=1;

void main() {

	posTC[gl_InvocationID] = posV[gl_InvocationID];
	normalTC[gl_InvocationID] = normalV[gl_InvocationID];
	
	if (gl_InvocationID == 0) {
		gl_TessLevelOuter[0] = olevel;
		gl_TessLevelOuter[1] = olevel;
		gl_TessLevelOuter[2] = olevel;
		gl_TessLevelInner[0] = ilevel;
	}
}