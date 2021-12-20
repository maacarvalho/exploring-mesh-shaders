
//perprimitiveNV in PerPrimitiveData
//{
    //int divs;
    //int mesh_id;
//};

//vec3 hsv2rgb(vec3 c) {
    //vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    //vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    //return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
//}

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

    //float hue = (mesh_id % 10) * 0.7 + 0.3 * float(mesh_id) / float(divs);
    //float hue = 0;
    //outputF = vec4(hsv2rgb(vec3(hue, 1.0, 0.75)), 1.0);
    //outputF = vec4(1.0, 0, 0,1);
//	outputF = vec4(hdr(outputF.rgb),1);
}

