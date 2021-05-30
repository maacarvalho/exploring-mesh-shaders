#!/usr/bin/bash

## Creates a mesh shader with different configurations
# Arguments:
# 1 - Local Size 
# 2 - Max Vertices
# 3 - Max Primitives
create_mesh_shader() {

    mesh_shader="#version 460
#extension GL_NV_mesh_shader : require
 
layout(local_size_x=$locs) in;
layout(triangles, max_vertices=$maxv, max_primitives=$maxp) out;

out PerVertexData
{
  vec3 lightDir;
  vec3 normal;
  vec2 texCoord;
} v_out[];   

uniform mat4 m_pvm;
uniform vec4 l_dir;
uniform mat4 m_view;
uniform mat3 m_normal;

uniform float scale;

layout(std430, binding = 1) readonly buffer verticesBuffer
{
  float vertices[];
};"

    if [[ ! -z "$normals_count" ]] 
    then

        mesh_shader+="
layout(std430, binding = 2) readonly buffer normalsBuffer
{
  float normals[];
};"

    fi    

    if [[ ! -z "$texcoords_count" ]] 
    then

        mesh_shader+="
layout(std430, binding = 3) readonly buffer texcoordsBuffer
{
  float texCoords[];
};"
    fi

    mesh_shader+="

layout(std430, binding = 4) readonly buffer indicesBuffer
{
  uint indices[];
};

layout(std430, binding = 5) readonly buffer primitivesBuffer
{
  uint primitives[];
};

layout(std430, binding = 6) readonly buffer meshletsBuffer
{
  uint meshlets[];
};

void main()
{

  // Inputs
  uint local_id  = gl_LocalInvocationID.x;
  uint global_id  = gl_GlobalInvocationID.x;
  uint meshlet_id = gl_WorkGroupID.x;
  uint workg_len = gl_WorkGroupSize.x;

  // Meshlet Info
  uint indices_start = meshlets[meshlet_id * 4 + 0];
  uint indices_count = meshlets[meshlet_id * 4 + 1];
  uint primitives_start = meshlets[meshlet_id * 4 + 2];
  uint primitives_count = meshlets[meshlet_id * 4 + 3];

  // No. Primitives
  gl_PrimitiveCountNV = primitives_count / 3;

  // Vertices
  uint vertices_per_thread = (indices_count + workg_len - 1) / workg_len;
  for (int i=0; i < vertices_per_thread; i++) {

    uint idx = min (i * workg_len + local_id, indices_count - 1);

    // Vertex
    uint vIndex = indices[(indices_start + idx) * 3 + 0];
    vec4 vertex = vec4(scale * vertices[vIndex * 4 + 0],
                       scale * vertices[vIndex * 4 + 1],
                       scale * vertices[vIndex * 4 + 2],
                       vertices[vIndex * 4 + 3]);

    gl_MeshVerticesNV[idx].gl_Position = m_pvm * vertex;

    // Light Direction
    v_out[idx].lightDir = normalize(vec3(m_view * l_dir));"
    
    if [[ ! -z "$normals_count" ]] 
    then

        mesh_shader+="
    uint nIndex = indices[(indices_start + idx) * 3 + 1];
    v_out[idx].normal = normalize(m_normal * vec3(normals[nIndex * 3 + 0],
                                                  normals[nIndex * 3 + 1],
                                                  normals[nIndex * 3 + 2]));"

    else

        mesh_shader+="
    v_out[idx].normal = normalize(m_normal * vec3(1, 1, 1));"

    fi    

    if [[ ! -z "$texcoords_count" ]] 
    then

        mesh_shader+="
    uint tIndex = indices[(indices_start + idx) * 3 + 2];
    v_out[idx].texCoord = vec2(texCoords[tIndex * 3 + 0],
                               texCoords[tIndex * 3 + 1]);"

    else 

        mesh_shader+="
    v_out[idx].texCoord = vec2(1, 1);"

    fi

    mesh_shader+="
  }

  // Primitives
  uint primitives_per_thread = (primitives_count / 3 + workg_len - 1) / workg_len;
  for (int i=0; i < primitives_per_thread; i++) {

    uint idx = min ((i * workg_len + local_id) * 3, primitives_count - 3);

    gl_PrimitiveIndicesNV[idx + 0] = primitives[primitives_start + idx + 0];
    gl_PrimitiveIndicesNV[idx + 1] = primitives[primitives_start + idx + 1];
    gl_PrimitiveIndicesNV[idx + 2] = primitives[primitives_start + idx + 2];

  }
 
}"

    echo "$mesh_shader"
}

## Creates a fragment shader for textured materials 
create_tex_frag_shader() {

    frag_shader="#version 460

uniform sampler2D tex;

in PerVertexData
{  
  vec3 lightDir;
  vec3 normal;
  vec2 texCoord;
};

out vec4 frag_color;

void main()
{
    vec3 ld = -normalize(lightDir);
	vec3 n = normalize(normal);
	float intensity = max(dot(ld, n), 0.0);

    vec4 color = texture (tex, texCoord);
    if (color.a <= 0.25) discard;

    frag_color = vec4(vec3(color * 0.3 + color * intensity), color.a);
}"

    echo "$frag_shader"

}

## Creates a fragment shader for diffuse materials 
create_diffuse_frag_shader() {

    frag_shader="#version 460

uniform vec3 diffuse;

in PerVertexData
{
  vec3 lightDir;
  vec3 normal;
  vec2 texCoord;
};

out vec4 frag_color;

void main()
{
    vec3 ld = -normalize(lightDir);
	vec3 n = normalize(normal);
	float intensity = max(dot(ld, n), 0.0);

    vec4 color = vec4(diffuse, 1.0);

    frag_color = vec4(vec3(color * 0.3 + color * intensity), color.a);
}"

    echo "$frag_shader"

}

## Creates a vertex shader that is equivalent to the mesh shader
create_vert_shader() {

    vert_shader="#version 460

uniform mat4 m_pvm;
uniform vec4 l_dir;
uniform mat4 m_view;
uniform mat3 m_normal;

uniform float scale;

in vec4 position;"

    if [[ ! -z "$normals_count" ]] 
    then 
        vert_shader+="
in vec4 normal;"
    fi 

    if [[ ! -z "$texcoords_count" ]]
    then
        vert_shader+="
in vec4 texCoord0;"
    fi

    vert_shader+="

out PerVertexData
{
  vec3 lightDir;
  vec3 normal;
  vec2 texCoord;
} v_out;  

void main()
{
	v_out.lightDir = normalize(vec3(m_view * l_dir));"

    if [[ ! -z "$normals_count" ]]
    then
        vert_shader+="
	v_out.normal = normalize(m_normal * vec3(normal));"
    else
        vert_shader+="
    v_out.normal = normalize(m_normal * vec3(1, 1, 1));"
    fi

    if [[ ! -z "$texcoords_count" ]]
    then
        vert_shader+="
	v_out.texCoord = vec2(texCoord0);"
    else
        vert_shader+="
	v_out.texCoord = vec2(1, 1);"
    fi

    vert_shader+="

	gl_Position = m_pvm * vec4(scale * position.xyz, position.w);
}"

    echo "$vert_shader"
}


## Creates a lua script for measure pipeline times
create_timer_lua_script () {

    echo "startTimer_${locs}_${maxv}_${maxp} = function()
	local timer = {}
	getAttr(\"RENDERER\", \"CURRENT\", \"TIMER\", 0, timer)

	local file = io.open(\"performance.csv\", \"a\")
    local str = string.gsub(string.format(\"%d;%d;%d;%f;\", $locs, $maxv, $maxp, timer[1]), \"[.]\", \",\")
	file:write(str)
	file:close()

end

stopTimer_${locs}_${maxv}_${maxp} = function()
	local timer = {}
	getAttr(\"RENDERER\", \"CURRENT\", \"TIMER\", 0, timer)

    local frame_counter = {}
    getAttr(\"RENDERER\", \"CURRENT\", \"FRAME_COUNT\", 0, frame_counter)
	
	local file = io.open(\"performance.csv\", \"a\");
    local str = string.gsub(string.format(\"%f;%f\\n\", timer[1], frame_counter[1]), \"[.]\", \",\")
	file:write(str)
	file:close()

end

"
}

## Creates a project 
create_proj () {
    
    echo "<?xml version=\"1.0\" ?>
<project name=\"Obj Renderer\" >
    <assets>
        <attributes>
            <attribute name=\"SCALE\" data=\"FLOAT\" type=\"RENDERER\" value=\"1\" />$attributes_str
        </attributes>

        <scenes>$scenes_str
        </scenes>

        <viewports>
            <viewport name=\"objViewport\">
                <CLEAR_COLOR r=\"0.0\" g=\"0.0\" b=\"0.0\" />
            </viewport>
        </viewports>		

        <cameras>
            <camera name=\"objCamera\" >
                <viewport name=\"objViewport\" />
                <TYPE value=\"PERSPECTIVE\"/>
                <FOV value = \"90\"/>
                <NEAR value= \"0.01\"/>
                <FAR value= \"10000\"/>
                <POSITION x=\"-2.75\" y=\"11\" z=\"-5\" w=\"1\" />
                <LOOK_AT_POINT x=\"-2.5\" y=\"11\" z=\"-4\" />
            </camera>
        </cameras>
        
        <lights>
            <light name=\"objLight\">
                <DIRECTION x=\"-2\" y=\"-6\" z=\"-2\" />
                <COLOR r=\"1\" g=\"1\" b=\"1\" />
            </light>
        </lights>
    
        <materialLibs>
            <materialLib filename=\"$basename.$maxv.$maxp.mlib\"/>
        </materialLibs>
    </assets>

    <pipelines mode="RUN_ALL">$pipelines_str
    </pipelines>

    <interface>
        <window label=\"Properties\" >
            <pipelineList label=\"Pipeline\" />
            <var label=\"Scale\" type=\"RENDERER\" context=\"CURRENT\" component=\"SCALE\" def=\"min=0 max=100\"/>
        </window>
    </interface>
</project>"

}

## Creates a Material Library
create_mlib () {

    echo "<?xml version=\"1.0\" ?>
<materialLib name=\"objMatLib\">
    
    <textures>$textures_str
    </textures>

	<shaders>$shaders_str
    </shaders>
   
	<buffers>$buffers_str
    </buffers>	

	<materials>$materials_str
	</materials>
</materialLib>"

}

## Defaults
locs=32
maxv=32
maxp=64

has_normals=1
has_texcoords=1
    
attributes_str=""
buffers_str=""
materials_str=""
mlibs_str=""
pipelines_str=""
scenes_str=""
shaders_str=""
textures_str=""

basename=""
