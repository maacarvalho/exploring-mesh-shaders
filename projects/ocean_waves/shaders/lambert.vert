
uniform sampler2DArray htk;
uniform int L;
uniform float choppyFactor;
uniform float ballScale = 1.0;

uniform mat4 m_pvm;
uniform mat3 m_normal;

in vec4 position;
in vec3 normal;

out vec3 normalV;

void main() {

	vec2 disp = vec2(50.0,50.0);
	vec4 pos = position;
	vec2 tc = disp/L;// + vec2(0.5, 0.5);
	pos.xyz *= ballScale;
	pos.xz += disp - texture(htk, vec3(tc, LAYER_DX_DZ_SX_SZ)).xy * choppyFactor;//( 1+choppyFactor/(1+(exp(-windSpeed+20)/5)));
	pos.y += texture(htk, vec3(tc, LAYER_Y_JXY_JXX_JYY)).r;
	
	normalV = normalize(m_normal * normal);
	
	gl_Position = m_pvm * pos;
}

