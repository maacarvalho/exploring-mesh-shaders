#version 410

perprimitiveNV in PerPrimitiveData 
{
    int divs;
    int mesh_id;
};

out vec4 color;

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main()
{
    float hue = float((int(mesh_id) % 2) * float(divs) * 0.5 + 0.5 * float(mesh_id)) / float(divs);
    //float hue = 0;
    color = vec4(hsv2rgb(vec3(hue, 1.0, 1.0)), 1.0);
}

