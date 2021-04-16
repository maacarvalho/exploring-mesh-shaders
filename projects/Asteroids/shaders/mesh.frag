#version 460
//#extension GL_NV_mesh_shader : enable

uniform vec4 l_dir;
uniform mat4 m_view;

uniform sampler2D tex;

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
    
    vec4 color = texture (tex, texCoord);

    frag_color = max(color * 0.25, color * intensity);
	//frag_color = vec4(1.0, 1.0, 1.0, 1.0);
}
