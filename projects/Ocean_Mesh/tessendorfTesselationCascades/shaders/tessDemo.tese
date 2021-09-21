
layout(quads, fractional_even_spacing, cw) in;

uniform sampler2DArray htk;
uniform sampler2D voronoi;

uniform	mat4 m_pvm, m_view;
uniform mat3 m_normal;
uniform vec3 camPos;


uniform int width;
uniform vec4 L;
uniform float windSpeed;
uniform float choppyFactor;
uniform int cascadeCount = 4;
uniform float gridSpacing = 5;

uniform float timer;
uniform vec4 l_dir;

in vec4 posTC[];

out Data {
	vec3 normal;
	vec3 l_dir;
	vec3 pos;
	vec3 world_norm;
	vec2 texCoord;
} DataOut;


#define uv gl_TessCoord


float height(float u, float v) {

	return 1; // this should be the patch maximum height
}


void main() {

	vec2 uvTE = uv.xy;
 
    vec4 res = posTC[0];

	// compute vertex position [0 .. tSize * gridSpacing]

	res.x += uvTE.s * gridSpacing;
	res.z += uvTE.t * gridSpacing;
	res.y = height(uvTE.s, uvTE.t) ;
	res.w = 1.0;
	
	vec4 p;
	DataOut.l_dir = vec3(normalize(- (m_view * l_dir)));
	
//	float yAtCam = texture(htk, vec3(camPos.xz/L, LAYER_Y_JXY_JXX_JYY)).r;

	vec2 tc, dxz = vec2(0,0), sxz = vec2(0,0);
	float height = 0;

	for (int casc = 0; casc < cascadeCount; ++casc) {

		tc = res.xz / L[casc];
		height += texture(htk, vec3(tc, LAYER_Y))[casc];
		dxz += vec2(texture(htk, vec3(tc, LAYER_DX))[casc], texture(htk, vec3(tc, LAYER_DZ))[casc]);
		sxz += vec2(texture(htk, vec3(tc, LAYER_SX))[casc], texture(htk, vec3(tc, LAYER_SZ))[casc]);
	}

	// wind based chopiness
	p.xz =  res.xz - dxz * choppyFactor;//( 1+choppyFactor/(1+(exp(-windSpeed+20)/5)));
	p.y = height;// + (camPos.y - yAtCam) -3;
	p.w = 1;
	
	// texture coordinates after vertex displacement
	vec3 normal = normalize(vec3( -sxz.x, 1,  -sxz.y));
	DataOut.world_norm = normal;
	DataOut.normal = normalize(m_normal * normal);
	DataOut.texCoord = res.xz;
	
	DataOut.pos = p.xyz;
	
	gl_Position = m_pvm * p;
}

