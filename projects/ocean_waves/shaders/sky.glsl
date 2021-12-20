// Sky stuff

uniform sampler2D sky;

#define LINEAR 0
#define EXPONENTIAL 1
uniform int sampling = LINEAR;

uniform int divisions = 8;
uniform int divisionsLightRay = 4;
uniform float exposure = 1.5;

uniform vec3 betaR = vec3(3.67044e-07, 1.11688e-06, 1.80601e-06);
uniform float betaMf = 5.76e-07;
uniform float Hr = 7994;
uniform float Hm = 1200;
uniform float g = 0.99;
uniform vec2 sunAngles;

const float PI = 3.14159265358979323846;
const float earthRadius = 6360000;
const float atmosRadius = 6420000;
const float fourPI = 4.0 * PI;


///////////////////////////////////////////////////////////////////////////
// 					Sky stuff 
///////////////////////////////////////////////////////////////////////////

vec3 skyColor(vec3 dir, vec3 sunDir, vec3 origin);


vec4 computeSkyReflection(vec3 refl) {

	vec2 sunAnglesRad = vec2(sunAngles.x, sunAngles.y) * vec2(PI/180);
	vec3 sunDir = vec3(cos(sunAnglesRad.y) * sin(sunAnglesRad.x),
							 sin(sunAnglesRad.y),
							-cos(sunAnglesRad.y) * cos(sunAnglesRad.x));
							
#ifdef COMPUTE_SKY_FOR_REFLECTION		
	return vec4(skyColor(refl, sunDir, vec3(0.0, earthRadius+100, 0.0)),1);
#else	
	float phi = atan(refl.z, refl.x);
	float theta = acos(refl.y);
	float aux = tan(phi);
	float x = sqrt((1-cos(theta))/(1+aux*aux));
	float y = aux*x;
	vec2 tcSky = vec2(x, y);
	float ka = length(tcSky);
	if (ka >= 0.99) 
		tcSky *= 0.99/ka;
//	tcSky.x = 1 - tcSky.x;
	tcSky = tcSky * 0.5 + 0.5;
	return texture(sky, tcSky );
#endif
}



float distToTopAtmosphere(vec3 origin, vec3 dir) {

	// project the center of the earth on to the ray
	vec3 u = vec3(-origin);
	// k is the signed distance from the origin to the projection
	float k = dot(dir,u);
	vec3 proj = origin + k * dir;
	
	// compute the distance from the projection to the atmosphere
	float aux = length(proj); 
	float dist = sqrt(atmosRadius * atmosRadius - aux*aux);
	
	dist += k;	
	return dist;
}


void initSampling(in float dist, in int div, out float quotient, out float segLength) {

	if (sampling == EXPONENTIAL) {
		quotient =  pow(dist, 1.0/(div));
		//segLength = quotient - 1;
	}
	else { // linear sampling
		segLength = dist/div;
	}
}


void computeSegLength(float quotient, float current, inout float segLength) {

	if (sampling == EXPONENTIAL) {
		segLength = current * quotient - current;
	}
	else { // linear sampling
	}
}




vec3 skyColor(vec3 dir, vec3 sunDir, vec3 origin) {

	float dist = distToTopAtmosphere(origin, dir);

	float quotient, quotientLight, segLengthLight, segLength;
	
	float cosViewSun = dot(dir, sunDir);
	
	vec3 betaM = vec3(betaMf);
	
	vec3 rayleigh = vec3(0);
	vec3 mie = vec3(0);
	
	float opticalDepthRayleigh = 0;
	float opticalDepthMie = 0;

	// phase functions
	float phaseR = 0.75 * (1.0 + cosViewSun * cosViewSun);

	float aux = 1.0 + g*g - 2.0*g*cosViewSun;
	float phaseM = 3.0 * (1 - g*g) * (1 + cosViewSun * cosViewSun) / 
					(2.0 * (2 + g*g) * pow(aux, 1.5)); 

	float current = 1;
	initSampling(dist, divisions, quotient, segLength);
	float height;
	for(int i = 0; i < divisions; ++i) {
		computeSegLength(quotient, current, segLength);
		vec3 samplePos = origin + (current + segLength * 0.5) * dir;
		height = length(samplePos) - earthRadius;
		if (height < 0) {
			break;
		}
		float hr = exp(-height / Hr) * segLength;
		float hm = exp(-height / Hm) * segLength;
		opticalDepthRayleigh += hr;
		opticalDepthMie += hm;
		
		float distLightRay = distToTopAtmosphere(samplePos, sunDir);
		initSampling(distLightRay, divisionsLightRay, quotientLight, segLengthLight);
		float currentLight = 1;
		float opticalDepthLightR = 0;
		float opticalDepthLightM = 0;
		int j = 0;
		
		for (; j < divisionsLightRay; ++j) {
			computeSegLength(quotientLight, currentLight, segLengthLight);
			vec3 sampleLightPos = samplePos + (currentLight + segLengthLight * 0.5) * sunDir;
			float heightLight = length(sampleLightPos) - earthRadius;
			if (heightLight < 0){
				break;
			}

			opticalDepthLightR += exp(-heightLight / Hr) * segLengthLight;
			opticalDepthLightM += exp(-heightLight / Hm) * segLengthLight;
			currentLight += segLengthLight;

		}

		if (j == divisionsLightRay) {
			vec3 tau = fourPI * betaR * (opticalDepthRayleigh + opticalDepthLightR) + 
					   fourPI * 1.1 * betaM *  (opticalDepthMie + opticalDepthLightM);
			vec3 att = exp(-tau);
			rayleigh += att * hr;
			mie += att * hm;
		}

		current += segLength;
	}
	vec3 result = (rayleigh *betaR * phaseR + mie * betaM * phaseM) * 20;
	vec3 white_point = vec3(1.0);
	result = pow(vec3(1.0) - exp(-result / white_point * exposure), vec3(1.0 / 2.2));

	return result;
}

