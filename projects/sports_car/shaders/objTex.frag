#version 460

uniform sampler2D tex;

in PerVertexData
{  
  vec3 lightDir;
  vec3 normal;
  vec2 texCoord;
};

out vec4 frag_color;

void main()
{
    vec3 ld = -normalize(lightDir);
	vec3 n = normalize(normal);
	float intensity = max(dot(ld, n), 0.0);

    vec4 color = texture (tex, texCoord);
    if (color.a <= 0.25) discard;

    frag_color = vec4(vec3(color * 0.3 + color * intensity), color.a);
}
