#version 410

perprimitiveNV in PerPrimitiveData 
{
    uint no_meshlets;
    uint meshlet_id;
};

out vec4 color;

float rand(float n){return fract(sin(n) * 43758.5453123);}

float noise(float p){
	float fl = floor(p);
  float fc = fract(p);
	return mix(rand(fl), rand(fl + 1.0), fc);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main()
{
    float hue = float(meshlet_id) / float(no_meshlets);
    //float hue = 0;
    color = vec4(hsv2rgb(vec3(noise(hue * 100000), 1.0, 1.0)), 1.0);
}

