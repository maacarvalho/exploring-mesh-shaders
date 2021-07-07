#version 410

layout(vertices = 4) out;

out vec4 posTC[];

uniform float level = 8.0; 
uniform float icols = 8.0; 
uniform float irows = 8.0; 
uniform float olevel = 8.0; 

void main() {

	posTC[gl_InvocationID] = gl_in[gl_InvocationID].gl_Position;
	
	if (gl_InvocationID == 0) {
		gl_TessLevelOuter[0] = irows;
		gl_TessLevelOuter[1] = icols;
		gl_TessLevelOuter[2] = irows;
		gl_TessLevelOuter[3] = icols;
		gl_TessLevelInner[0] = icols;
		gl_TessLevelInner[1] = irows;
		//gl_TessLevelOuter[0] = level;
		//gl_TessLevelOuter[1] = level;
		//gl_TessLevelOuter[2] = level;
		//gl_TessLevelOuter[3] = level;
		//gl_TessLevelInner[0] = level;
		//gl_TessLevelInner[1] = level;
	}
}
