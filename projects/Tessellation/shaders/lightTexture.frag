#version 410

uniform	mat4 viewMatrix;
uniform	sampler2D texUnit;
uniform vec3 lightDir;

in vec3 normalTE;
in vec2 texCoordTE;
out vec4 outputF;

void main() {

	vec4 color;
	vec4 amb;
	float intensity;
	vec3 n;
	
	vec3 l = normalize(vec3(viewMatrix * -(vec4(lightDir, 0.0))));
	n = normalize(normalTE);	
	intensity = max(dot(l,n),0.0);
	
	color = texture(texUnit, texCoordTE) ;
	
	outputF = color * (intensity+ 0.2);
}