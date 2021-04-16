#version 420
 
layout (triangles) in;
layout (triangle_strip, max_vertices=3) out;

uniform mat3 m_normal;
uniform mat4 m_proj_view;

out Data {
    vec4 color;
	vec3 normal;
} DataOut;

vec4 distinctColor (uint idx) {

  if (idx >= 20) return vec4 (1.0, 1.0, 1.0, 1.0); // White is error

  vec4 colors[20] = { vec4(0.90196, 0.09804, 0.29412, 1.0),
                      vec4(0.23529, 0.70588, 0.29412, 1.0),
                      vec4(1.00000, 0.88235, 0.09804, 1.0),
                      vec4(0.00000, 0.50980, 0.78431, 1.0),
                      vec4(0.96078, 0.50980, 0.18824, 1.0),
                      vec4(0.56863, 0.11765, 0.70588, 1.0),
                      vec4(0.27451, 0.94118, 0.94118, 1.0),
                      vec4(0.94118, 0.19608, 0.90196, 1.0),
                      vec4(0.82353, 0.96078, 0.23529, 1.0),
                      vec4(0.98039, 0.74510, 0.83137, 1.0),
                      vec4(0.00000, 0.50196, 0.50196, 1.0),
                      vec4(0.86275, 0.74510, 1.00000, 1.0),
                      vec4(0.66667, 0.43137, 0.15686, 1.0),
                      vec4(1.00000, 0.98039, 0.78431, 1.0),
                      vec4(0.50196, 0.00000, 0.00000, 1.0),
                      vec4(0.66667, 1.00000, 0.76471, 1.0),
                      vec4(0.50196, 0.50196, 0.00000, 1.0),
                      vec4(1.00000, 0.84314, 0.70588, 1.0),
                      vec4(0.00000, 0.00000, 0.50196, 1.0),
                      vec4(0.50196, 0.50196, 0.50196, 1.0)};

  return colors[idx];

}

void main()
{

    DataOut.color = distinctColor(gl_PrimitiveIDIn);

	DataOut.normal = normalize(m_normal * gl_in[0].gl_Position.xyz);
	gl_Position = m_proj_view * gl_in[0].gl_Position;
	EmitVertex();

    DataOut.normal = normalize(m_normal * gl_in[1].gl_Position.xyz);
	gl_Position = m_proj_view * gl_in[1].gl_Position;
	EmitVertex();

    DataOut.normal = normalize(m_normal * gl_in[2].gl_Position.xyz);
	gl_Position = m_proj_view * gl_in[2].gl_Position;
	EmitVertex();

    EndPrimitive();
}