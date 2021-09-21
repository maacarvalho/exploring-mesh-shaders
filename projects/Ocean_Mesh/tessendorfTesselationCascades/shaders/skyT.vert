#version 430

#define M_PI 3.1415926535897932384626433832795

uniform mat4 m_proj;

in vec4 position;
in vec2 texCoord0;

out vec2 texCoord;

void main() {
	
	texCoord = texCoord0;
	
	float z = 5000 * tan(30*M_PI/180);
	
	vec4 p = vec4(position.x * z, position.y * z, -5000, 1);
	
	gl_Position = m_proj * p;
}