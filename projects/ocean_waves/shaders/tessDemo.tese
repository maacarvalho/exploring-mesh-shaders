
layout(quads, fractional_even_spacing, cw) in;

uniform sampler2DArray htk;
uniform sampler2D voronoi;

uniform	mat4 m_pvm, m_view, m_model, m_proj, m_godView;
uniform mat3 m_normal;
uniform vec3 camPos;

uniform int camMode;

uniform int width;
uniform int L;
uniform float windSpeed;
uniform float choppyFactor;
uniform float gridSpacing = 5;

uniform float A = 1, Q = 0.3, w = 0.4, phi = 1;
uniform vec2 D = vec2(1,1);
uniform float timer;
uniform vec4 l_dir;

in vec4 posTC[];
in uint tcID[];

out Data {
	vec3 normal;
	vec3 l_dir;
	vec3 pos;
	vec3 world_norm;
	vec2 texCoord;
} DataOut;

// layout(std430, binding = 1) writeonly buffer debugBuffer
// {
//     vec4 printf[];
// };

#define uv gl_TessCoord


float height(float u, float v) {

	return 1; // this should be the patch maximum height
}


void main() {

    vec4 res = posTC[0];

    // printf[tcID[0]] = res;

	// compute vertex position [0 .. tSize * gridSpacing]

	res.x += uv.s * gridSpacing;
	res.z += uv.t * gridSpacing;
	res.y = height(uv.s, uv.t) ;
	res.w = 1.0;
	
	vec4 p;
	DataOut.l_dir = vec3(normalize(- (m_view * l_dir)));
	
	float yAtCam = texture(htk, vec3(camPos.xz/L, LAYER_Y_JXY_JXX_JYY)).r;
	vec2 tc = res.xz / L;

	vec4 dy = texture(htk, vec3(tc, LAYER_Y_JXY_JXX_JYY));
	vec4 ds = texture(htk, vec3(tc, LAYER_DX_DZ_SX_SZ));
	// wind based chopiness
	p.xz =  res.xz - ds.xy * choppyFactor;//( 1+choppyFactor/(1+(exp(-windSpeed+20)/5)));
	p.y = dy.r;// + (camPos.y - yAtCam) -3;
	p.w = 1;
	
	// texture coordinates after vertex displacement
	vec2 slope = ds.zw;
	vec3 normal = normalize(vec3( -slope.x, 1,  -slope.y));
	DataOut.world_norm = normal;
	DataOut.normal = normalize(m_normal * normal);
	DataOut.texCoord = tc;
	
	DataOut.pos = p.xyz;
	
//#define TESTE
#ifdef TESTE
	float v = texture(voronoi, DataOut.texCoord).r * 10;
	p.y = v;
#endif	
	
    mat4 god_pvm = m_proj * m_godView * m_model;

    if (camMode == 1) gl_Position = m_pvm * p;
    else              gl_Position = god_pvm * p;
}

