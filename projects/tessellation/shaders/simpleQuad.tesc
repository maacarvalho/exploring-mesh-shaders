#version 410

layout(vertices = 4) out;

out vec4 posTC[];

uniform float level = 8.0; 
uniform float icols = 8.0; 
uniform float irows = 8.0; 
uniform float olevel0 = 8.0; 
uniform float olevel1 = 8.0; 
uniform float olevel2 = 8.0; 
uniform float olevel3 = 8.0; 

void main() {

	posTC[gl_InvocationID] = gl_in[gl_InvocationID].gl_Position;
	
	if (gl_InvocationID == 0) {
		gl_TessLevelOuter[0] = olevel0;
		gl_TessLevelOuter[1] = olevel1;
		gl_TessLevelOuter[2] = olevel2;
		gl_TessLevelOuter[3] = olevel3;
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
