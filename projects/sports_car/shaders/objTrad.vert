#version 460

uniform mat4 m_pvm;
uniform vec4 l_dir;
uniform mat4 m_view;
uniform mat3 m_normal;

uniform float scale;

in vec4 position;
in vec4 normal;

out PerVertexData
{
  vec3 lightDir;
  vec3 normal;
  vec2 texCoord;
} v_out;  

void main()
{
	v_out.lightDir = normalize(vec3(m_view * l_dir));
	v_out.normal = normalize(m_normal * vec3(normal));
	v_out.texCoord = vec2(1, 1);

	gl_Position = m_pvm * vec4(scale * position.xyz, position.w);
}
