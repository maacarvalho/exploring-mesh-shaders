#version 420
 
layout(triangles) in;
layout (line_strip, max_vertices=6) out;

uniform mat4 projViewModelMatrix;
uniform float len = 0.3;

in vec3 normalTE[];


 void main()
{
	// normal for first vertex
	gl_Position = projViewModelMatrix * gl_in[0].gl_Position;
	EmitVertex();

	gl_Position = projViewModelMatrix * (gl_in[0].gl_Position + len * vec4(normalTE[0],0.0));
	EmitVertex();

	EndPrimitive();
	

	// normal for second vertex
	gl_Position = projViewModelMatrix * gl_in[1].gl_Position;
	EmitVertex();

	gl_Position = projViewModelMatrix * (gl_in[1].gl_Position + len * vec4(normalTE[1], 0.0));
	EmitVertex();

	EndPrimitive();


	// normal for third vertex
	gl_Position = projViewModelMatrix * gl_in[2].gl_Position;
	EmitVertex();

	gl_Position = projViewModelMatrix * (gl_in[2].gl_Position + len * vec4(normalTE[2],0.0));
	EmitVertex();

	EndPrimitive();
}

