#version 410

perprimitiveNV in PerPrimitiveData 
{
    uint divs;
    uint mesh_id;
};

out vec4 color;

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main()
{
    float hue = float(mesh_id) / float(divs * divs);
    //float hue = 0;
    color = vec4(hsv2rgb(vec3(hue, 1.0, 1.0)), 1.0);
}

