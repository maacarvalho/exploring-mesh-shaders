




void main() {

	vec2 slope = vec2(0,0);
	for (int casc = 0; casc < cascadeCount; ++casc) {

		slope += vec2(texture(htk, vec3(DataIn.texCoord/L[casc], LAYER_SX))[casc], 
					  texture(htk, vec3(DataIn.texCoord/L[casc], LAYER_SZ))[casc]);
	}
	vec3 wn = normalize(vec3( -slope.x,  1,  -slope.y));
//	vec3 wn = normalize(DataIn.normal);
	
	
	vec4 color = computeOceanColor(wn);
	
#if (FOAM != NO_FOAM)
	vec4 foamV = texture(foam, DataIn.texCoord);
	float f = computeFoamFactor();
	outputF = color * (1-f) + foamV * f;
#else
	outputF = color;
#endif		

}

