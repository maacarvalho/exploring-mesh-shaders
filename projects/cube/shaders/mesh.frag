#version 460
//#extension GL_NV_mesh_shader : enable

perPrimitiveNV in PerPrimitiveData 
{
  vec4 color;
};

out vec4 frag_color;

void main()
{
	frag_color = color;
}