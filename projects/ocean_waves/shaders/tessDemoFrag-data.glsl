in Data {
	vec3 normal;
	vec3 l_dir;
	vec3 pos;
	vec3 world_norm;
	vec2 texCoord;
} DataIn;

uniform sampler2DArray htk;
uniform sampler2D voronoi, foam;
uniform vec3 camPos;
uniform int width;
uniform float timer;
uniform float windSpeed;
uniform vec2 windDir;
uniform float choppyFactor;
uniform int L;

out vec4 outputF;

// Ocean
uniform float oceanDepth = 60;
uniform vec3 oceanTransmittance = vec3(98.2, 95.8, 57.0);
uniform vec3 oceanFloorColor = vec3(244/255.0, 236/255.0, 236/255.0);

const float indAir = 1.000293; //air refraction index
const float indWater = 1.333; //water index of refraction
const float Eta = indAir/indWater;
uniform float power = 5.0;

layout(std430, binding = 0) buffer oceanInfo{
	vec4 info[];
};

