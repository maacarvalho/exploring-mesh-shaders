#version 430

uniform vec3 camUp = vec3(0,1,0);
uniform vec3 camView = vec3(0,0,-1);
uniform float fov = 65;
uniform float ratio = 1;

uniform int divisions = 4;
uniform int divisionsLightRay = 4;
uniform float exposure = 1.5;

#define FISH_EYE 1
#define REGULAR 0
const int cameraMode = FISH_EYE;

#define LINEAR 0
#define EXPONENTIAL 1
uniform int sampling = LINEAR;


uniform vec3 betaR = vec3(3.8e-6f, 13.5e-6f, 33.1e-6f);
uniform float betaMf = 2.1e-5f;
uniform float Hr = 7994;
uniform float Hm = 1200;
const float g = 0.98;
uniform vec2 sunAngles;

const float PI = 3.14159265358979323846;
const float earthRadius = 6360000;
const float atmosRadius = 6420000;
const float fourPI = 4.0 * PI;

in vec2 texCoord;

out vec4 outputF;

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




vec3 skyColor(vec3 dir, vec3 sunDir, vec3 origin, float dist) {

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

	//if (cosViewSun >= 0.999192306417128873735516482698) {
		//result =   exp(-fourPI*opticalDepthRayleigh * betaR - fourPI*opticalDepthMie * betaM)*20 ;
		//result *=   exp(- opticalDepthMie * betaM) ;
		
	//}

	return result;
}


void main() {

	vec3 result;
	vec2 sunAnglesRad = vec2(sunAngles.x, sunAngles.y) * vec2(PI/180);
	vec3 sunDir = vec3(cos(sunAnglesRad.y) * sin(sunAnglesRad.x),
							 sin(sunAnglesRad.y),
							-cos(sunAnglesRad.y) * cos(sunAnglesRad.x));
							
	float angle = tan(fov * PI / 180.0 * 0.5);
	vec3 origin = vec3(0.0, earthRadius+10, 0.0);
	vec2 tc = texCoord * 2.0 - 1.0;
	
	if (cameraMode == REGULAR) { // normal camera
	
		vec2 pos = tc * vec2(ratio*angle, angle);
		vec3 camRight = cross(camView, camUp);
		vec3 dir = camUp * pos.y + camRight * pos.x + camView;
		dir = normalize(dir);
		float dist = distToTopAtmosphere(origin, dir);
		
		result = skyColor(dir, sunDir, origin, dist);
		float zNear = -1;
		float zFar = -10000;
		float z = -1000;
		if (length(result) < 0.1)
			gl_FragDepth = (- 2.0 * zNear * zFar / (zFar - zNear) - z * (zFar + zNear)/(zFar - zNear))/-z;
		else
			gl_FragDepth = 0.0;
	}
	else { // fish eye camera

		float x = tc.x * ratio;
		float y = tc.y;
		float z = x*x + y*y;
		if (z < 1) {
			float phi = atan(y,x);
			float theta = acos(1-z);
			vec3 dir = vec3(sin(theta) * cos(phi), cos(theta), sin(theta) * sin(phi));
			float dist = distToTopAtmosphere(origin, dir);
			
			result = skyColor(dir, sunDir, origin, dist);
		}
		else 
			result = vec3(0);
	}
		
	// tone mapping
	vec3 white_point = vec3(1.0);
	result = pow(vec3(1.0) - exp(-result / white_point * exposure), vec3(1.0 / 2.2));
	
	outputF = vec4(result, 1);
}