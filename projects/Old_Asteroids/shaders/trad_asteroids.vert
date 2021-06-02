#version 460

uniform mat4 m_pvm;
uniform vec4 l_dir;
uniform mat4 m_view;
uniform mat3 m_normal;

uniform float scale;
uniform float displacement;

in vec4 position;
in vec4 normal;
in vec4 texCoord0;

out PerVertexData
{
  vec3 normal;
  vec2 texCoord;
  vec3 lightDir;
} v_out;  

vec4 transform (vec4 vertex) {

  vec3 transformed = vertex.xyz * scale;
  transformed.x += displacement;
  transformed.z -= 2.50 * gl_InstanceID;

  return vec4 (transformed, vertex.w);

}

void main()
{
	v_out.normal = normalize(m_normal * vec3(normal));
	v_out.texCoord = vec2(texCoord0);
	v_out.lightDir = normalize(vec3(m_view * l_dir));
	gl_Position = m_pvm * transform(position);
}
