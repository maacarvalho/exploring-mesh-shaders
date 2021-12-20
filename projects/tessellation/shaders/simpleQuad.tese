#version 410

//layout(quads, equal_spacing, ccw) in;
//layout(quads, fractional_odd_spacing, ccw) in;
layout(quads, fractional_even_spacing, ccw) in;

uniform	mat4 projViewModelMatrix;

in vec4 posTC[];

out perVertexData 
{
    vec2 texCoordTE;
};


uniform float height_noise_frequency   = 0.1;
uniform float height_noise_amplitude   = 1.0;
uniform float height_noise_power       = 3.5;
uniform int height_noise_octaves       = 50;
uniform float height_noise_persistance = 0.5;
uniform float height_noise_lacunarity  = 2.0;

float rand(vec2 co) { return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453); }

////////////////////////////////////////////////////////////////////////////
//                                                                        //
// Description : Array and textureless GLSL 2D simplex noise function.    //
//      Author : Ian McEwan, Ashima Arts.                                 //
//  Maintainer : stegu                                                    //
//     Lastmod : 20110822 (ijm)                                           //
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.     //
//               Distributed under the MIT License. See LICENSE file.     //
//               https://github.com/ashima/webgl-noise                    //
//               https://github.com/stegu/webgl-noise                     //
//                                                                        //
//                                                                        //

vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }

vec2 mod289(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }

vec3 permute(vec3 x) { return mod289(((x*34.0)+1.0)*x); }

float snoise(vec2 v) {
  
  const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                      0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                     -0.577350269189626,  // -1.0 + 2.0 * C.x
                      0.024390243902439); // 1.0 / 41.0
  // First corner
  vec2 i  = floor(v + dot(v, C.yy) );
  vec2 x0 = v -   i + dot(i, C.xx);

  // Other corners
  vec2 i1;
  //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
  //i1.y = 1.0 - i1.x;
  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  // x0 = x0 - 0.0 + 0.0 * C.xx ;
  // x1 = x0 - i1 + 1.0 * C.xx ;
  // x2 = x0 - 1.0 + 2.0 * C.xx ;
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;

  // Permutations
  i = mod289(i); // Avoid truncation effects in permutation
  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
		+ i.x + vec3(0.0, i1.x, 1.0 ));

  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
  m = m*m ;
  m = m*m ;

  // Gradients: 41 points uniformly over a line, mapped onto a diamond.
  // The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)

  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;

  // Normalise gradients implicitly by scaling m
  // Approximation of: m *= inversesqrt( a0*a0 + h*h );
  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

  // Compute final noise value at P
  vec3 g;
  g.x  = a0.x  * x0.x  + h.x  * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 130.0 * dot(m, g);

}
//                                                                        //
////////////////////////////////////////////////////////////////////////////

float max_height () {

  float amp = height_noise_amplitude, height = 0;
	
	for(int i = 0; i < height_noise_octaves; i++, amp *= height_noise_persistance) {
		
    height += 1.0 * amp;
	
  }

  return height;

}

float height (vec2 position) {

  float freq = height_noise_frequency, amp = height_noise_amplitude, height = 0, max_height = max_height();
	
  // Calculating height using snoise ( height -> [-max_height, max_heigth] )
	for(int i = 0; i < height_noise_octaves; i++, amp *= height_noise_persistance, freq *= height_noise_lacunarity) {
		
    height += snoise(freq * position) * amp;
	
  }

  // Height -> [0,1]
  height = height / max_height * 0.5 + 0.5;

  // Applying the power (height -> [0, 1])
  height = pow(height, height_noise_power);

  // Height -> [-1, max_height - 1]
  return height * 2 * max_height - 1;
  
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void main() {

	float u = gl_TessCoord.x;
	float v = gl_TessCoord.y;
	float w = 1 - u - v;
	
	vec4 p1 = mix(posTC[0],posTC[1],u);
	vec4 p2 = mix(posTC[3],posTC[2],u);
	vec4 p = mix(p1, p2, v);
	//p.z = 0.25 * height (vec2(u, v));
	gl_Position = projViewModelMatrix * p;
    texCoordTE = vec2(u, v);
}

