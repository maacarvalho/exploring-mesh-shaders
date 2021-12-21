#version 460

uniform vec3 diffuse;

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

    vec4 color = vec4(diffuse, 1.0);

    frag_color = vec4(vec3(color * 0.3 + color * intensity), color.a);
}
