




void main() {

    vec2 slope = texture(htk, vec3(DataIn.texCoord, LAYER_DX_DZ_SX_SZ)).zw;
    vec3 wn = normalize(vec3( -slope.x,  1,  -slope.y));//
//	vec3 wn = normalize(DataIn.normal);
    
    
    vec4 color = computeOceanColor(wn);
    
#if (FOAM != NO_FOAM)
    vec4 foamV = texture(foam, DataIn.texCoord);
    float f = computeFoamFactor();
    outputF = color * (1-f) + foamV * f;
#else
    outputF = color;
#endif		

    //outputF = vec4(1.0, 0, 0,1);
//	outputF = vec4(hdr(outputF.rgb),1);
}

