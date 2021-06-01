#version 410

layout(triangles, fractional_odd_spacing, ccw) in;

uniform	mat4 projViewModelMatrix;
uniform	mat3 normalMatrix;

in vec4 normalTC[];
in vec4 posTC[];

out vec3 normalTE;

void main() {

	vec4 b300 = posTC[0];
	vec4 b030 = posTC[1];
	vec4 b003 = posTC[2];
	vec4 n1 = normalTC[0];
	vec4 n2 = normalTC[1];
	vec4 n3 = normalTC[2];
	
	float w12 = dot (b030 - b300, n1);
	float w21 = dot (b300 - b030, n2);
	
	float w13 = dot (b003 - b300, n1);
	float w31 = dot (b300 - b003, n3);
	
	float w23 = dot (b003 - b030, n2);
	float w32 = dot (b030 - b003, n3);
	
	vec4 b210 = (2*b300 + b030 - w12*n1) / 3 ;
	vec4 b120 = (2*b030 + b300 - w21*n2) / 3 ;

	vec4 b021 = (2*b030 + b003 - w23*n2) / 3 ;
	vec4 b012 = (2*b003 + b030 - w32*n3) / 3 ;

	vec4 b102 = (2*b003 + b300 - w31*n3) / 3 ;
	vec4 b201 = (2*b300 + b003 - w13*n1) / 3 ;

	vec4 E = (b210 + b120 + b021 + b012 + b201 + b102) / 6;
	vec4 V = (b300 + b030 + b003) / 3;

	vec4 b111 = E + (E - V) / 2;
	
	float u = gl_TessCoord.x;
	float v = gl_TessCoord.y;
	float w = gl_TessCoord.z;
	
	vec4 res = b300 * w*w*w + b030 * u*u*u + b003 * v*v*v +
				b210 * 3 * w*w*u + b120 * 3 * w*u*u + b201 * 3 * w*w*v +
				b021 * 3 * u*u*v + b102 * 3 * w*v*v + b012 * 3 * u*v*v +
				b111 * 6 *w*u*v;
	
	float v12 = 2 * (dot (b030 - b300, n1+n2)/dot (b030 - b300, b030 - b300));
	float v23 = 2 * (dot (b003 - b030, n2+n3)/dot (b003 - b030, b003 - b030));
	float v31 = 2 * (dot (b300 - b003, n3+n1)/dot (b003 - b300, b003 - b300));
	
	vec4 n110 = normalize ( n1 + n2 - v12 *(b030 - b300));
	vec4 n011 = normalize ( n2 + n3 - v23 *(b003 - b030));
	vec4 n101 = normalize ( n3 + n1 - v31 *(b300 - b003));
	
	normalTE = normalize(vec3(n1 *w*w + n2 *u*u + n3 *v*v +
				n110 *w*u + n011 * u*v + n101 * w*v));
				
/* 	vec4 du = 3 * b030*u*u - 3*w*w*b300 + (6*u*w - 3*u*u)* b120
				+ 6 *u*v*b021 - 3*v*v*b102 + 3 *v*v*b012 + 
				(3*w*w-6*w*u)*b210 - 6*w*v*b201 +
				(6*w*v - 6*u*v) * b111;
				
	vec4 dv = 3 * b003*v*v + -3*w*w*b300 - 3 * u*u*b120 +
	3*u*u*b021 + (6*v*w-3*v*v)*b102 + 6*v*u*b012 
	- 6*w*u*b210 + (3*w*w - 6*w*v)*b201 + (6*w*u - 6*u*v)*b111;
			normalTE = normalize(cross(vec3(du), vec3(dv)));
 */	gl_Position = res;//projViewModelMatrix * res;
}

