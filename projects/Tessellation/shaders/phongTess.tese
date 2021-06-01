#version 410

layout(triangles, fractional_odd_spacing, ccw) in;

uniform	mat4 projViewModelMatrix;
uniform	mat3 normalMatrix;

uniform float alpha = 0.75;

in vec4 normalTC[];
in vec4 posTC[];

out vec3 normalTE;

void main() {

	vec4 P1 = posTC[0];
	vec4 P2 = posTC[1];
	vec4 P3 = posTC[2];
	vec4 n1 = normalTC[0];
	vec4 n2 = normalTC[1];
	vec4 n3 = normalTC[2];
	
	float u = gl_TessCoord.x;
	float v = gl_TessCoord.y;
	float w = 1 - u - v;
	
	vec4 Puv = P1*w + P2*u + P3*v;
	vec4 Proj1 = Puv - (dot(Puv-P1, n1)) * n1;
	vec4 Proj2 = Puv - (dot(Puv-P2, n2)) * n2;
	vec4 Proj3 = Puv - (dot(Puv-P3, n3)) * n3;
	
	normalTE = normalize(normalMatrix * vec3(n1*w + n2*u + n3*v));
				
	vec4 res =  (1 - alpha) * Puv  + alpha * (Proj1 * w + Proj2 * u + Proj3 * v);
	
	gl_Position = projViewModelMatrix * res;
}

