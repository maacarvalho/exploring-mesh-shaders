#version 330

layout (std140) uniform Matrices {
	mat4 m_pvm;
	mat4 m_viewModel;
	mat4 m_view;
	mat3 m_normal;
};

layout (std140) uniform Lights {
	vec4 l_pos;	// global space
};

in vec4 position; // local space
in vec3 normal;	  // local space

out Data {
	vec3 normal;
	vec3 eye;
	vec3 lightDir;
} DataOut;

void main () {

	// position on camera space
	vec4 pos = m_viewModel * position; 
	// light position in camera space
	vec4 lpos = m_view * l_pos;
	// light direction in camera space
	DataOut.lightDir = vec3(lpos - pos);
	// normal in camera space
	DataOut.normal = normalize(m_normal * normal);
	// vector from vertex to camera, also in camera space
	DataOut.eye = vec3(-pos);

	gl_Position = m_pvm * position;	
}