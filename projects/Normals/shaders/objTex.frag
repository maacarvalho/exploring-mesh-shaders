#version 460
//#extension GL_NV_mesh_shader : enable

uniform sampler2D tex;

in PerVertexData
{
  vec3 normal;
  vec2 texCoord;
  vec3 lightDir;
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
	//frag_color = vec4(1.0, 1.0, 1.0, 1.0);
}
