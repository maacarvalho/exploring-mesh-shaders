#version 410

uniform	mat4 viewMatrix;
uniform vec4 lightDir;
uniform vec4 diffuse;

in vec3 normalTE;

out vec4 outputF;

void main() {

	float intensity;
	vec3 n, l;
	
	l = normalize(vec3(viewMatrix * -lightDir));
	n = normalize(normalTE);	
	intensity = max(dot(l,n),0.0);
	
	outputF = (diffuse * intensity) + diffuse * 0.2;
}