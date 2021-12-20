
float schlickRatio (vec3 rayDirection, vec3 normal) {

	float f =  pow((1.0 - indWater) / (1.0 + indWater) , 2);
	float schlick = f + (1 - f) * pow(1 - dot(-rayDirection,normal), power);
	
	return clamp(schlick, 0 ,1);
}


// From white-caps master Dupuy and Bruneton
vec3 hdr(vec3 L) {
    L = L * 1.05;//hdrExposure;
    L.r = L.r < 1.413 ? pow(L.r * 0.38317, 1.0 / 2.2) : 1.0 - exp(-L.r);
    L.g = L.g < 1.413 ? pow(L.g * 0.38317, 1.0 / 2.2) : 1.0 - exp(-L.g);
    L.b = L.b < 1.413 ? pow(L.b * 0.38317, 1.0 / 2.2) : 1.0 - exp(-L.b);
    return L;
}





float computeFoamFactor() {

	float f = 0;
	
#if (FOAM == USE_VERTICAL_ACCELERATION)

#define minFoam 0
#define maxFoam 7
	float whiteCap = texture(htk, vec3(DataIn.texCoord, LAYER_Y_JXY_JXX_JYY)).y * choppyFactor;
	vec4 foamV = texture(foam, DataIn.texCoord*2);
	f = pow(smoothstep(1,7, whiteCap), 2.0);
	f = 2*f;
	outputF = outputF * (1-f) + foamV * f;

#elif (FOAM == USE_JACOBIAN)
	float jxx= 1, jyy = 1, jxy = 0;
	jxx += texture(htk, vec3(DataIn.texCoord, LAYER_Y_JXY_JXX_JYY)).z * choppyFactor;
	jyy += texture(htk, vec3(DataIn.texCoord, LAYER_Y_JXY_JXX_JYY)).w * choppyFactor;
	jxy += texture(htk, vec3(DataIn.texCoord, LAYER_Y_JXY_JXX_JYY)).y * choppyFactor;

	float det = jxx * jyy - jxy*jxy;
	float whiteCap = det;
	
	vec4 foamV = texture(foam, DataIn.texCoord*2);
	f = 1-smoothstep(0.0, 0.7, whiteCap);
	if (whiteCap < 0.0)
		f = 1;
#endif	
	return f;
}


vec4 computeOceanColor(vec3 wn) {

	vec2 sunAnglesRad = vec2(sunAngles.x, sunAngles.y) * vec2(M_PI/180);
	vec3 sunDir = vec3(cos(sunAnglesRad.y) * sin(sunAnglesRad.x),
							 sin(sunAnglesRad.y),
							-cos(sunAnglesRad.y) * cos(sunAnglesRad.x));

	vec3 viewDir = normalize(DataIn.pos - camPos);
	vec3 reflDir = normalize(reflect(viewDir, wn));	
	if (reflDir.y < 0)
		reflDir.y = -reflDir.y;

	float spec = pow (max(0, dot(reflDir, sunDir)), 128);
	
	vec4 skyC = computeSkyReflection(reflDir);	
	
	vec4 shallowColor = vec4(0.0, 0.64, 0.68, 1);
	vec4 deepColor = vec4(0.02, 0.05, 0.10, 1);

	float relativeHeight = clamp((DataIn.pos.y - (-40)) / (80), 0.0, 1.0);
	vec4 heightColor = (relativeHeight * shallowColor + (1 - relativeHeight) * deepColor) * 0.8;
	float ratio = schlickRatio(viewDir, wn);
	float refCoeff = pow(max(dot(wn, -viewDir), 0.0), 0.3);	// Smaller power will have more concentrated reflect.
	vec4 reflectColor = (ratio) * skyC;
	float specCoef = min(0.1, pow(max(dot(viewDir, reflDir), 0.0), 64) * 3);

	//return skyC;
	vec4 c =  (1 - specCoef) * (heightColor+reflectColor) + vec4(spec) ;
	return c;// * skyC;

}



vec3 intersect(vec3 origin, vec3 direction, vec3 planeNormal, float D) {

	float calpha = dot(normalize(direction),normalize(-planeNormal));
	if (calpha > 0) {
	
		float k = (origin.y - D) * calpha;
		float x = origin.x + k * direction.x;
		float z = origin.z + k * direction.z;
		return vec3(x,D,z);
	}
	//caso o vetor refratado não intercete o fundo do mar
	else return vec3(0,-D*100,0);
}


/*vec3 transmistance(float dist){

	// order is inverse because wavelength info is stored in ascendent order
	vec3 trans = oceanTransmittance.bgr * 0.01;
	return vec3(pow(trans.r, dist), pow(trans.g, dist), pow(trans.b, dist));
}
*/
/*
vec4 computeOceanColor(vec3 transDir) {

	// bottom of the sea normal
	vec3 of_normal = vec3(0, 1, 0);
	
	vec2 oceanSurfaceHeight = texelFetch(htk, ivec3(0), int(log2(width))).bg;
	
	if (info[0].r < oceanSurfaceHeight.r)
		info[0].r = oceanSurfaceHeight.r;
	float d = info[0].g;
	if (d > oceanSurfaceHeight.g - oceanDepth) {
		d = oceanSurfaceHeight.g - oceanDepth;
		info[0].g = d;
	}
	
	
	vec3 of_point = intersect(DataIn.pos, transDir, of_normal, d);
	vec3 of_vec = of_point - DataIn.pos;
	//float of_dist = sqrt(pow(of_vec.x, 2) + pow(of_vec.y, 2) + pow(of_vec.z, 2));
	float of_dist = length(of_vec);
	return vec4( transmistance(2 * of_dist), 0.0);
}
*/
