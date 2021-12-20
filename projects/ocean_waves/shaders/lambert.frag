#version 330

uniform mat4 m_view;
uniform vec4 l_dir;

in vec3 normalV;

out vec4 outputF;

void main() {

	vec3 n = normalize(normalV);
	
	vec3 lDir = normalize(vec3(m_view * l_dir));
	
	float intensity = max (0.0, dot(-lDir, n));
	
	outputF = vec4(intensity,0,0,1);
}