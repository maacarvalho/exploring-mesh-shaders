#version 410

uniform vec4 l_dir;
uniform mat4 m_view;

in Data {
    vec4 color;
	vec3 normal;
};

out vec4 frag_color;

void main()
{
    vec3 ld = normalize(vec3(m_view * -l_dir));	
	vec3 n = normalize(normal);
    
	float intensity = max(dot(ld, n), 0.0);
	
	frag_color = max(color * 0.25, color * intensity);
}