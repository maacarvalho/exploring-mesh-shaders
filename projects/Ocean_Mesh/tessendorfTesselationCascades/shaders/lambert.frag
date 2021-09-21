#version 330

const float PI = 3.14159265358979323846;

uniform mat4 m_view;
uniform vec2 sunAngles;

in vec3 normalV;

out vec4 outputF;

void main() {

	vec2 sunAnglesRad = vec2(sunAngles.x, sunAngles.y) * vec2(PI/180);
	vec3 sunDir = vec3(cos(sunAnglesRad.y) * sin(sunAnglesRad.x),
							 sin(sunAnglesRad.y),
							-cos(sunAnglesRad.y) * cos(sunAnglesRad.x));
							
	vec3 n = normalize(normalV);
	
	vec3 lDir = normalize(vec3(m_view * vec4(sunDir,0)));
	
	float intensity = max (0.0, dot(lDir, n));
	
	outputF = vec4(intensity + 0.3,0,0,1);
}