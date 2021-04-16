#version 460
//#extension GL_NV_mesh_shader : enable

uniform vec4 l_dir;
uniform mat4 m_view;

uniform vec3 diffuse;

in PerVertexData
{
  vec3 normal;
  vec2 texCoord;
};

out vec4 frag_color;

void main()
{
    vec3 ld = normalize(vec3(m_view * -l_dir));	
	vec3 n = normalize(normal);
    
	float intensity = max(dot(ld, n), 0.0);
    
    vec4 color = vec4(diffuse, 1.0);

    frag_color = max(color * 0.25, color * intensity);
}
