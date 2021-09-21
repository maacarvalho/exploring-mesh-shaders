#version 430

uniform int gridSize;
uniform float gridSpacing = 5;
uniform vec3 camPos;

in vec4 position;

out vec4 posV;
out int vInstanceID;

void main() {

    vInstanceID = gl_InstanceID;
    int index = gl_InstanceID;
    float shift = gridSize * gridSpacing * 0.5;
	
    ivec2 camShift = ivec2(0);//ivec2(camPos.xz / gridSpacing);
    
	int col = index % gridSize;
	int row = index / gridSize;
    posV = vec4(col * gridSpacing - shift + camShift.x * gridSpacing, 0, 
                row * gridSpacing - shift + camShift.y * gridSpacing, 1);
}




