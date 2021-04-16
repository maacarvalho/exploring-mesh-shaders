#version 460
//#extension GL_NV_mesh_shader : require

perprimitiveNV in PerPrimitiveData 
{
  vec4 color;
} p_in;

out vec4 color;

void main()
{
	color = p_in.color;
}