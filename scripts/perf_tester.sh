#!/usr/bin/bash

## Creates a mesh shader with different configurations
# Arguments:
# 1 - Local Size 
# 2 - Max Vertices
# 3 - Max Primitives
create_mesh_shader() {

    echo "#version 460
#extension GL_NV_mesh_shader : require
 
layout(local_size_x=$1) in;
layout(triangles, max_vertices=$2, max_primitives=$3) out;

out PerVertexData
{
  vec3 normal;
  vec2 texCoord;
  vec3 lightDir;
} v_out[];   

uniform mat4 m_pvm;
uniform vec4 l_dir;
uniform mat4 m_view;
uniform mat3 m_normal;

uniform float scale;

layout(std430, binding = 1) readonly buffer verticesBuffer
{
  float vertices[];
};

layout(std430, binding = 2) readonly buffer normalsBuffer
{
  float normals[];
};

layout(std430, binding = 3) readonly buffer texcoordsBuffer
{
  float texCoords[];
};

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
    uint vIndex = indices[(indices_start + idx) * 3 + 0];
    uint nIndex = indices[(indices_start + idx) * 3 + 1];
    uint tIndex = indices[(indices_start + idx) * 3 + 2];

    vec4 vertex = vec4(scale * vertices[vIndex * 4 + 0],
                       scale * vertices[vIndex * 4 + 1],
                       scale * vertices[vIndex * 4 + 2],
                       vertices[vIndex * 4 + 3]);

    vec3 normal = vec3(normals[nIndex * 3 + 0],
                       normals[nIndex * 3 + 1],
                       normals[nIndex * 3 + 2]);

    vec2 texCoord = vec2(texCoords[tIndex * 3 + 0],
                         texCoords[tIndex * 3 + 1]);

    gl_MeshVerticesNV[idx].gl_Position = m_pvm * vertex;
    v_out[idx].normal = normalize(m_normal * normal);
    v_out[idx].texCoord = texCoord;
    v_out[idx].lightDir = normalize(vec3(m_view * l_dir));
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
}

## Creates a fragment shader that uses texture coordinates for the .obj
create_tex_frag_shader() {

    echo "#version 460

uniform sampler2D tex;

in PerVertexData
{
  vec3 normal;
  vec2 texCoord;
  vec3 lightDir;
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
	//frag_color = vec4(1.0, 1.0, 1.0, 1.0);
}"

}

## Creates a fragment shader that uses a diffuse color for the .obj
create_color_frag_shader() {

    echo "#version 460

uniform vec3 diffuse;

in PerVertexData
{
  vec3 normal;
  vec2 texCoord;
  vec3 lightDir;
};

out vec4 frag_color;

void main()
{
    vec3 ld = -normalize(lightDir);	
	vec3 n = normalize(normal);
    
	float intensity = max(dot(ld, n), 0.0);
    
    vec4 color = vec4(diffuse, 1.0);

    frag_color = vec4(vec3(color * 0.3 + color * intensity), 1.0);
}"

}

## Creates a vertex shader that is equivalent to the mesh shader
create_vert_shader() {

    echo "#version 460

uniform mat4 m_pvm;
uniform vec4 l_dir;
uniform mat4 m_view;
uniform mat3 m_normal;

uniform float scale;

in vec4 position;
in vec4 normal;
in vec4 texCoord0;

out PerVertexData
{
  vec3 normal;
  vec2 texCoord;
  vec3 lightDir;
} v_out;  

void main()
{
	v_out.normal = normalize(m_normal * vec3(normal));
	v_out.texCoord = vec2(texCoord0);
	v_out.lightDir = normalize(vec3(m_view * l_dir));

	gl_Position = m_pvm * vec4(scale * position.xyz, position.w);
}"

}
## Creates a lua script for measure pipeline times
create_timer_lua_script () {

    echo "startTimer_$1_$2_$3 = function()
	local timer = {}
	getAttr(\"RENDERER\", \"CURRENT\", \"TIMER\", 0, timer)

	local file = io.open(\"performance.csv\", \"a\")
    local str = string.gsub(string.format(\"%d;%d;%d;%f;\", $1, $2, $3, timer[1]), \"[.]\", \",\")
	file:write(str)
	file:close()

end

stopTimer_$1_$2_$3 = function()
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

## Creates a project for testing combinations
# Arguments
# 1 - String with the basename of .obj file
# 2 - String with all the diffuse colors
# 3 - String with all the pipelines
create_proj () {
    
    echo "<?xml version=\"1.0\" ?>
<project name=\"Obj Renderer\" >
    <assets>
        <attributes>
            <attribute name=\"SCALE\" data=\"FLOAT\" type=\"RENDERER\" value=\"0.1\" />$attributes_str
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
                <FAR value= \"100\"/>
                <POSITION x=\"5\" y=\"5\" z=\"5\" w=\"1\" />
                <LOOK_AT_POINT x=\"0\" y=\"0\" z=\"0\" />
            </camera>
        </cameras>
        
        <lights>
            <light name=\"objLight\">
                <DIRECTION x=\"-2\" y=\"-6\" z=\"-2\" />
                <COLOR r=\"1\" g=\"1\" b=\"1\" />
            </light>
        </lights>
    
        <materialLibs>
            <materialLib filename=\"$basename.mlib\"/>
        </materialLibs>
    </assets>
    
    <pipelines mode="RUN_ALL">$pipelines_str
    </pipelines>

    <interface>
        <window label=\"Properties\" >
            <pipelineList label=\"Pipeline\" />
            <var label=\"Scale\" type=\"RENDERER\" context=\"CURRENT\" component=\"SCALE\" def=\"min=0 max=1\"/>
        </window>
    </interface>
</project>"

}

## Creates a Material Library for testing combinations
# Arguments
# 1 - String with the listing of textures
# 2 - String with the listing of shaders
# 3 - String with the listing of buffers
# 4 - String with the listing of materials
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


## Counts the size of the buffers and the number of materials
# Arguments
# 1 - Prefix of the buffers
measure_buffers () {

    sizes=$(wc $1*)

    vertices_count=$(echo "$sizes" | awk '/vertices.buf/ {print $2}')
    normals_count=$(echo "$sizes" | awk '/normals.buf/ {print $2}')
    texcoords_count=$(echo "$sizes" | awk '/texcoords.buf/ {print $2}')

    declare -i material_count=0
    for (( ; ; ))
    do

        mat=$(printf "%03d" $material_count)

        if [[ $(echo "$sizes" | awk "/\.$mat\./ {print \$0}") ]]
        then
           
            indices_count[$mat]=$(echo "$sizes" | awk "/.$mat.indices.buf/ {print \$2}")
            primitives_count[$mat]=$(echo "$sizes" | awk "/.$mat.primitives.buf/ {print \$2}")
            meshlets_count[$mat]=$(echo "$sizes" | awk "/.$mat.meshlets.buf/ {print \$2}")
            meshes_count[$mat]=$(echo "$sizes" | awk "/.$mat.meshlets.buf/ {print \$1}")
            diffuse_colors[$mat]=$(awk "/^$mat/ {printf \"x=\\\"%s\\\" y=\\\"%s\\\" z=\\\"%s\\\"\", \$2, \$3, \$4}" ${1}.materials.buf)
            if [[ ! $(awk "/^$mat/ {print \$5}" ${1}.materials.buf) -eq "" ]] 
            then
                textures[$mat]=$(awk "/^$mat/ {print \$5}" ${1}.materials.buf)
            fi
        else
            break
        fi
        
        material_count+=1 
    done

    #echo "================================== Counters ==============================="
    #echo "Vertex Count: $vertices_count;"
    #echo "Normals Count: $normals_count;"
    #echo "TexCoords Count: $texcoords_count;"

    
    #for m in "${!indices_count[@]}"
    #do

        #echo "Indices Count ($m):  ${indices_count[$m]};"
        #echo "Primitives Count ($m):  ${primitives_count[$m]};"
        #echo "Meshlets Count ($m):  ${meshlets_count[$m]};"
        #echo "Meshes Count ($m):  ${meshes_count[$m]};"
        #echo "Diffuse ($m):  ${diffuse_colors[$m]};"
        #echo "Texture ($m):  ${textures[$m]};"

    #done

}

add_traditional_pipeline () {

    # SCENES

    scenes_str+="
            <scene name=\"objScene\" type=\"Scene\">
                <file name=\"$basename\"/>
            </scene>"

    # PIPELINES

    pipelines_str+="
        <pipeline name=\"Traditional\" default=\"true\" frameCount = 500>
            <preScript file=\"scripts/times.0.0.0.lua\" script=\"startTimer_0_0_0\" />
            <pass class=\"default\" name=\"traditionalPass\">
                <scenes>
                    <scene name=\"objScene\" />
                </scenes>
                <camera name=\"objCamera\" />
                <lights>
                    <light name=\"objLight\" />
                </lights>
                <materialMaps>
					<map fromMaterial=\"*\"  	toLibrary=\"objMatLib\" 	toMaterial=\"tradMat_000\" />
                </materialMaps>
            </pass>
            <postScript file=\"scripts/times.0.0.0.lua\" script=\"stopTimer_0_0_0\" />
        </pipeline>"
 
    # SHADERS

    if [ ! "${#textures[@]}" -eq 0 ] 
    then
        shaders_str+="
        <shader name=\"tradTex\" 	                  vs = \"shaders/objTrad.vert\" 
										            ps = \"shaders/objTex.frag\" />"

    else
        shaders_str+="
        <shader name=\"tradColor\"                    vs = \"shaders/objTrad.vert\" 
										            ps = \"shaders/objColor.frag\" />"
    fi

    # MATERIALS

    for m in "${!indices_count[@]}"
    do
        materials_str+="
        <material name=\"tradMat_$m\">
        "

        if [ ! -z "${textures[$m]}" ] 
        then

            materials_str+="
            <textures>
                <texture name=\"tex$m\" UNIT=0 />
            </textures>
	        
            <shader name=\"tradTex\" >
				<values>
                    <valueof uniform=\"tex\"
                             type=\"TEXTURE_BINDING\" context=\"CURRENT\"
                             component=\"UNIT\" id=0 />
            "

        else 
            
            materials_str+="
            <shader name=\"tradColor\" >
				<values>
                    <valueof uniform=\"diffuse\"
                             type=\"RENDERER\" context=\"CURRENT\"
                             component=\"DIFFUSE_$m\" />
            "
        fi

        materials_str+="
					<valueof uniform=\"m_pvm\" 
							 type=\"RENDERER\" context=\"CURRENT\" 
							 component=\"PROJECTION_VIEW_MODEL\" />
							 
					<valueof uniform=\"m_normal\" 
							 type=\"RENDERER\" context=\"CURRENT\" 
							 component=\"NORMAL\" />
							 
					<valueof uniform=\"m_view\" 
							 type=\"RENDERER\" context=\"CURRENT\" 
							 component=\"VIEW\" />
							 
					<valueof uniform=\"l_dir\" 
							 type=\"LIGHT\" context=\"objLight\"
							 component=\"DIRECTION\" />

                    <valueof uniform=\"scale\" 
							 type=\"RENDERER\" context=\"CURRENT\"
                             component=\"SCALE\" />
                </values>
            </shader>

        </material>
        "

    done
    
}

add_pipelines () {

    pipelines_str+="
        <pipeline name=\"Mesh_$1_$2_$3\" default=\"true\" frameCount = 500>
            <preScript file=\"scripts/times.$1.$2.$3.lua\" script=\"startTimer_$1_$2_$3\" />"
    
    for m in "${!indices_count[@]}"
    do
        pipelines_str+="
            <pass class=\"mesh\" name=\"meshPass_$1_$2_$3_$m\">
                <camera name=\"objCamera\" />
                <lights>
                    <light name=\"objLight\" />
                </lights>
                <material name=\"meshMat_$1_$2_$3_$m\" fromLibrary=\"objMatLib\" count=\"${meshes_count[$m]}\" />
            </pass>"
    done

    pipelines_str+="
            <postScript file=\"scripts/times.$1.$2.$3.lua\" script=\"stopTimer_$1_$2_$3\" />
        </pipeline>"

}

add_attributes () {

    if [ -z "$attributes_str" ]
    then
        attributes_str=""
        for m in "${!indices_count[@]}"
        do
            if [ -z "${textures[$m]}" ] 
            then 
                attributes_str+="
            <attribute name=\"DIFFUSE_$m\" data=\"VEC3\" type=\"RENDERER\" ${diffuse_colors[$m]} />"
            fi
        done
    fi

}

add_textures () {

    if [ -z "$textures_str" ]
    then
        textures_str=""
        for m in "${!indices_count[@]}"
        do
            if [ ! -z "${textures[$m]}" ]
            then
                textures_str+="
            <texture name=\"tex${m}\" filename=\"${textures[$m]#$dirname[/\\]}\" mipmap=true />"
            fi
        done
    fi

}

add_shaders () {
    
    shaders_str+="
        <shader name=\"meshColor_$1_$2_$3\"         ms = \"shaders/obj.$1.$2.$3.mesh\" 
										            ps = \"shaders/objColor.frag\" />"
    if [ ! "${#textures[@]}" -eq 0 ] 
    then
        shaders_str+="
        <shader name=\"meshTex_$1_$2_$3\" 	        ms = \"shaders/obj.$1.$2.$3.mesh\" 
										            ps = \"shaders/objTex.frag\" />"
    fi
 
}

add_buffers () {

    buffers_str+="
        <buffer name=\"verticesBuffer_$1_$2\" >
            <file name=\"$folder/$basename.vertices.buf\"/>
            <DIM x=$vertices_count y=1 z=1 />
			<structure>
				<field value=\"FLOAT\" />
			</structure>
		</buffer>
        <buffer name=\"normalsBuffer_$1_$2\" >
            <file name=\"$folder/$basename.normals.buf\"/>
            <DIM x=$normals_count y=1 z=1 />
			<structure>
				<field value=\"FLOAT\" />
			</structure>
		</buffer>"

    
    if [ ! "${#textures[@]}" -eq 0 ] 
    then
        buffers_str+="
        <buffer name=\"texcoordsBuffer_$1_$2\" >
            <file name=\"$folder/$basename.texcoords.buf\"/>
            <DIM x=$texcoords_count y=1 z=1 />
			<structure>
				<field value=\"FLOAT\" />
			</structure>
        </buffer>"
    fi

    for m in "${!indices_count[@]}"
    do
        buffers_str+="
        <buffer name=\"indicesBuffer_$1_$2_$m\" >
            <file name=\"$folder/$basename.$m.indices.buf\"/>
            <DIM x=${indices_count[$m]} y=1 z=1 />
			<structure>
				<field value=\"UINT\" />
			</structure>
        </buffer>    
        <buffer name=\"primitivesBuffer_$1_$2_$m\" >
            <file name=\"$folder/$basename.$m.primitives.buf\"/>
            <DIM x=${primitives_count[$m]} y=1 z=1 />
			<structure>
				<field value=\"UINT\" />
			</structure>
        </buffer>
        <buffer name=\"meshletsBuffer_$1_$2_$m\" >
            <file name=\"$folder/$basename.$m.meshlets.buf\"/>
            <DIM x=${meshlets_count[$m]} y=1 z=1 />
			<structure>
				<field value=\"UINT\" />
			</structure>
        </buffer>"
    done

}

add_materials () {

    for m in "${!indices_count[@]}"
    do
        materials_str+="
        <material name=\"meshMat_$1_$2_$3_$m\">

            <buffers>
                <buffer name=\"verticesBuffer_$2_$3\">
					<TYPE value=\"SHADER_STORAGE\" />
    				<BINDING_POINT value=\"1\" />
                </buffer>
                <buffer name=\"normalsBuffer_$2_$3\">
					<TYPE value=\"SHADER_STORAGE\" />
    				<BINDING_POINT value=\"2\" />
                </buffer>"


        if [ ! -z "${textures[$m]}" ]
        then
            materials_str+="
                <buffer name=\"texcoordsBuffer_$2_$3\">
					<TYPE value=\"SHADER_STORAGE\" />
    				<BINDING_POINT value=\"3\" />
				</buffer>"
        fi

        materials_str+="
				<buffer name=\"indicesBuffer_$2_$3_$m\">
					<TYPE value=\"SHADER_STORAGE\" />
    				<BINDING_POINT value=\"4\" />
                </buffer>
				<buffer name=\"primitivesBuffer_$2_$3_$m\">
					<TYPE value=\"SHADER_STORAGE\" />
    				<BINDING_POINT value=\"5\" />
				</buffer>
				<buffer name=\"meshletsBuffer_$2_$3_$m\">
					<TYPE value=\"SHADER_STORAGE\" />
    				<BINDING_POINT value=\"6\" />
				</buffer>
            </buffers>
            "

        if [ ! -z "${textures[$m]}" ] 
        then

            materials_str+="
            <textures>
                <texture name=\"tex$m\" UNIT=0 />
            </textures>
	        
            <shader name=\"meshTex_$1_$2_$3\" >
				<values>
                    <valueof uniform=\"tex\"
                             type=\"TEXTURE_BINDING\" context=\"CURRENT\"
                             component=\"UNIT\" id=0 />
            "

        else 
            
            materials_str+="
            <shader name=\"meshColor_$1_$2_$3\" >
				<values>
                    <valueof uniform=\"diffuse\"
                             type=\"RENDERER\" context=\"CURRENT\"
                             component=\"DIFFUSE_$m\" />
            "
        fi

        materials_str+="
					<valueof uniform=\"m_pvm\" 
							 type=\"RENDERER\" context=\"CURRENT\" 
							 component=\"PROJECTION_VIEW_MODEL\" />
							 
					<valueof uniform=\"m_normal\" 
							 type=\"RENDERER\" context=\"CURRENT\" 
							 component=\"NORMAL\" />
							 
					<valueof uniform=\"m_view\" 
							 type=\"RENDERER\" context=\"CURRENT\" 
							 component=\"VIEW\" />
							 
					<valueof uniform=\"l_dir\" 
							 type=\"LIGHT\" context=\"objLight\"
							 component=\"DIRECTION\" />

                    <valueof uniform=\"scale\" 
							 type=\"RENDERER\" context=\"CURRENT\"
                             component=\"SCALE\" />
                </values>
            </shader>

        </material>
        "

    done

}


if [ $# -ne 2 ] 
then

    echo "Illegal number of parameters" >&2
    exit 1

else

    filepath=$1
    dirname=$(dirname $filepath)
    basename=$(basename $filepath)

    #max_vertices=( 256 128 64 32 16 8 )
    #max_primitives=( 512 256 128 64 32 16 8 )
    #local_size=( 32 16 8 )
    max_vertices=( 256 128 )
    max_primitives=( 512 256 )
    local_size=( 32 16 )

    declare vertices_count
    declare normals_count
    declare texcoords_count
    declare -A indices_count
    declare -A primitives_count
    declare -A meshlets_count
    declare -A meshes_count
    declare -A diffuse_colors
    declare -A textures

    scenes_str=""
    pipelines_str=""
    attributes_str=""
    textures_str=""
    shaders_str=""
    buffers_str=""
    materials_str=""

    # Creating frag shaders
    [[ ! -d "$dirname/shaders" ]] && mkdir "$dirname/shaders"
    [[ ! -f "$dirname/shaders/objTex.frag" ]] && create_tex_frag_shader > "$dirname/shaders/objTex.frag"
    [[ ! -f "$dirname/shaders/objColor.frag" ]] && create_color_frag_shader > "$dirname/shaders/objColor.frag"

    # Creating vertex shader
    [[ ! -f "$dirname/shaders/objTrad.vert" ]] && create_vert_shader > "$dirname/shaders/objTrad.vert"

    # Creating performance script for traditional pipeline
    [[ ! -d "$dirname/scripts" ]] && mkdir "$dirname/scripts"
    [[ ! -f "$dirname/scripts/times.0.0.0.lua" ]] && create_timer_lua_script 0 0 0 > "$dirname/scripts/times.0.0.0.lua"

    materials_loaded=0

    for maxv in "${max_vertices[@]}"
    do
        for maxp in "${max_primitives[@]}" 
        do
            folder=$(printf "buffers/%03d_%03d" $maxv $maxp)

            # Creating mesh shader
            for locs in "${local_size[@]}"
            do
                # Creating mesh shader
                [[ ! -f "$dirname/shaders/obj.$locs.$maxv.$maxp.mesh" ]] && create_mesh_shader $locs $maxv $maxp > "$dirname/shaders/obj.$locs.$maxv.$maxp.mesh"

                # Creating lua script for performance measuring
                [[ ! -f "$dirname/scripts/times.$locs.$maxv.$maxp.lua" ]] && create_timer_lua_script $locs $maxv $maxp > "$dirname/scripts/times.$locs.$maxv.$maxp.lua"
            done

            # Folder for the buffers
            [[ ! -d $dirname/$folder ]] && mkdir $dirname/$folder

            if [[ ! -f "$dirname/$folder/$basename.vertices.buf" ]]
            then
                
                # Create buffers
                lua obj_converter.lua $filepath $maxv $maxp

                # Copy buffers to folder
                mv $filepath.* $dirname/$folder

            fi

            # Getting information on the materials of the mesh
            measure_buffers "$dirname/$folder/$basename"

            # Measure buffers
            if [[ $materials_loaded -eq 0 ]]
            then

                # Creating traditional pipeline
                add_traditional_pipeline 

                materials_loaded=1

            fi

            add_attributes
            add_textures

            for locs in "${local_size[@]}"
            do
                add_pipelines $locs $maxv $maxp
                add_shaders $locs $maxv $maxp
                add_materials $locs $maxv $maxp
            done

            add_buffers $maxv $maxp

        done
    done

    create_proj > $filepath.nau
    create_mlib > $filepath.mlib

fi
