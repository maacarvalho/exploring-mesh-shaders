#version 410

layout(quads, fractional_odd_spacing, ccw) in;

uniform	mat4 projViewModelMatrix;
uniform	mat3 normalMatrix;

in vec4 posTC[];

out vec3 normalTE;
out vec2 texCoordTE;

mat4 M = mat4(vec4(-1, 3, -3, 1), vec4(3, -6, 3, 0), vec4 (-3, 3, 0, 0), vec4(1 ,0, 0, 0));

void main() {

	vec4 p00 = posTC[ 0];
	vec4 p10 = posTC[ 1];
	vec4 p20 = posTC[ 2];
	vec4 p30 = posTC[ 3];
	vec4 p01 = posTC[ 4];
	vec4 p11 = posTC[ 5];
	vec4 p21 = posTC[ 6];
	vec4 p31 = posTC[ 7];
	vec4 p02 = posTC[ 8];
	vec4 p12 = posTC[ 9];
	vec4 p22 = posTC[10];
	vec4 p32 = posTC[11];
	vec4 p03 = posTC[12];
	vec4 p13 = posTC[13];
	vec4 p23 = posTC[14];
	vec4 p33 = posTC[15];
	float u = gl_TessCoord.x;
	float v = gl_TessCoord.y;

	texCoordTE = vec2(u,v);

	vec4 U = vec4(u*u*u, u*u, u, 1);
	vec4 V = vec4(v*v*v, v*v, v, 1);
	vec4 du = vec4( 3 * U.y, 2 * u, 1, 0);
	vec4 dv = vec4( 3 * V.y, 2 * v, 1, 0);

	mat4 Px = mat4( p00.x, p10.x, p20.x, p30.x, p01.x, p11.x, p21.x, p31.x, p02.x, p12.x, p22.x, p32.x, p03.x, p13.x, p23.x, p33.x);
	mat4 Py = mat4( p00.y, p10.y, p20.y, p30.y, p01.y, p11.y, p21.y, p31.y, p02.y, p12.y, p22.y, p32.y, p03.y, p13.y, p23.y, p33.y);
	mat4 Pz = mat4( p00.z, p10.z, p20.z, p30.z, p01.z, p11.z, p21.z, p31.z, p02.z, p12.z, p22.z, p32.z, p03.z, p13.z, p23.z, p33.z);

	vec4 res;

/*  
 // Versão baseada em multiplicação de matrizes
	mat4 MPxM = M *	Px * M;
	mat4 MPyM = M *	Py * M;
	mat4 MPzM = M *	Pz * M;

	res.x = dot  (U, MPxM * V);
	res.z = -dot (U, MPyM * V);
	res.y = dot  (U, MPzM * V);
	res.w = 1;

	vec3 dpdu;
	dpdu.x = dot  (du, MPxM * V);
	dpdu.z = -dot (du, MPyM * V);
	dpdu.y = dot  (du, MPzM * V);

	vec3 dpdv;
	dpdv.x = dot  (U, MPxM * dv);
	dpdv.z = -dot (U, MPyM * dv);
	dpdv.y = dot  (U, MPzM * dv);
 */
 
// versão que só multiplica matrizes por vectores
	vec4 MV = M * V;
	vec4 MPxMV = M * (Px * MV);
	vec4 MPyMV = M * (Py * MV);
	vec4 MPzMV = M * (Pz * MV);
	res.x = dot(U , MPxMV);
	res.z = -dot(U , MPyMV);
	res.y = dot(U , MPzMV);
	res.w =  1;

	vec3 dpdu;
	dpdu.x = dot (du, MPxMV);
	dpdu.z = -dot (du, MPyMV);
	dpdu.y = dot (du, MPzMV);


	vec3 dpdv;
	MV = M * dv;
	MPxMV = M * (Px * MV);
	MPyMV = M * (Py * MV);
	MPzMV = M * (Pz * MV);
	dpdv.x = dot (U, MPxMV);
	dpdv.z = -dot (U, MPyMV);
	dpdv.y = dot (U, MPzMV);
	 
	normalTE = normalize(normalMatrix * cross( dpdu.xyz, dpdv.xyz ));

	gl_Position = projViewModelMatrix * res;
}

