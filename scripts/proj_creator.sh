#!/usr/bin/bash

if [ $# -ne 1 ] 
then

    echo "Illegal number of parameters" >&2
    exit 1

else
    
    basename=$(basename $1)
    dirname=$(dirname $1)

    sizes=$(wc $1*)

    echo "================================== Sizes =================================="
    echo "$sizes"

    vertices_count=$(echo "$sizes" | awk '/vertices.buf/ {print $2}')
    normals_count=$(echo "$sizes" | awk '/normals.buf/ {print $2}')
    texcoords_count=$(echo "$sizes" | awk '/texcoords.buf/ {print $2}')
    
    declare -A indices_count
    declare -A primitives_count
    declare -A meshlets_count
    declare -A meshes_count
    declare -A diffuse_colors
    declare -A textures

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
            textures[$mat]=$(awk "/^$mat/ {print \$5}" ${1}.materials.buf)

        else
            break
        fi
        
        material_count+=1 
    done

    echo "================================== Counters ==============================="
    echo "Vertex Count: $vertices_count"
    echo "Normals Count: $normals_count"
    echo "TexCoords Count: $texcoords_count"

    
    for m in "${!indices_count[@]}"
    do

        echo "Indices Count ($m):  ${indices_count[$m]}"
        echo "Primitives Count ($m):  ${primitives_count[$m]}"
        echo "Meshlets Count ($m):  ${meshlets_count[$m]}"
        echo "Meshes Count ($m):  ${meshes_count[$m]}"
        echo "Diffuse ($m): " ${diffuse_colors[$m]}
        echo "Texture ($m): " ${textures[$m]}

    done

    echo "================================== Project ================================"

    proj_str="<?xml version=\"1.0\" ?>
<project name=\"Obj Renderer\" >
    <assets>
        <attributes>
            <attribute name=\"SCALE\" data=\"FLOAT\" type=\"RENDERER\" value=\"0.1\" />"
    
    for m in "${!indices_count[@]}"
    do
        if [ -z "${textures[$m]}" ] 
        then 
            proj_str+="
            <attribute name=\"DIFFUSE_$m\" data=\"VEC3\" type=\"RENDERER\" ${diffuse_colors[$m]} />"
        fi
    done

    proj_str+="
        </attributes>

        <scenes>
            <scene name=\"objScene\" type=\"Scene\">
                <SCALE x=0.1 y=0.1 z=0.1 />
                <file name=\"$basename\"/>
            </scene>
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
    
    <pipelines>
        <pipeline name=\"Mesh Pipeline\" default=\"true\">"
    
    for m in "${!indices_count[@]}"
    do
        proj_str+="
            <pass class=\"mesh\" name=\"meshPass$m\">
                <camera name=\"objCamera\" />
                <lights>
                    <light name=\"objLight\" />
                </lights>
                <material name=\"mat$m\" fromLibrary=\"objMatLib\" count=\"${meshes_count[$m]}\" />
            </pass>"
    done

    proj_str+="
        </pipeline>
        <pipeline name=\"Traditional Pipeline\" default=\"true\">
            <pass class=\"default\" name=\"vertGeomPass\">
                <camera name=\"objCamera\" />
                <scenes>
                    <scene name=\"objScene\" />
                </scenes>
                <lights>
                    <light name=\"objLight\" />
                </lights>
            </pass>	
        </pipeline>
    </pipelines>

    <interface>
        <window label=\"Properties\" >
            <pipelineList label=\"Pipeline\" />
            <var label=\"Scale\" type=\"RENDERER\" context=\"CURRENT\" component=\"SCALE\" def=\"min=0 max=1\"/>
        </window>
    </interface>
</project>"

    echo "$proj_str" > ${1}.nau

    echo "================================== Material Lib ==========================="

    mlib_str="<?xml version=\"1.0\" ?>
<materialLib name=\"objMatLib\">
    
    <textures>"

    for m in "${!indices_count[@]}"
    do
        if [ ! -z "${textures[$m]}" ]
        then
            mlib_str+="
        <texture name=\"tex${m}\" filename=\"${textures[$m]#$dirname[/\\]}\" mipmap=true />"
        fi
    done

    mlib_str+="
    </textures>

	<shaders>
        <shader name=\"meshColorShaders\" 	ms = \"shaders/obj.mesh\" 
										    ps = \"shaders/objColor.frag\" />
        <shader name=\"meshTexShaders\" 	    ms = \"shaders/obj.mesh\" 
										    ps = \"shaders/objTex.frag\" />
    </shaders>
   
	<buffers>
		<buffer name=\"verticesBuffer\" >
            <file name=\"$basename.vertices.buf\"/>
            <DIM x=$vertices_count y=1 z=1 />
			<structure>
				<field value=\"FLOAT\" />
			</structure>
		</buffer>
        <buffer name=\"normalsBuffer\" >
            <file name=\"$basename.normals.buf\"/>
            <DIM x=$normals_count y=1 z=1 />
			<structure>
				<field value=\"FLOAT\" />
			</structure>
		</buffer>
        <buffer name=\"texcoordsBuffer\" >
            <file name=\"$basename.texcoords.buf\"/>
            <DIM x=$texcoords_count y=1 z=1 />
			<structure>
				<field value=\"FLOAT\" />
			</structure>
        </buffer>"


    for m in "${!indices_count[@]}"
    do
        mlib_str+="
        <buffer name=\"indicesBuffer$m\" >
            <file name=\"$basename.$m.indices.buf\"/>
            <DIM x=${indices_count[$m]} y=1 z=1 />
			<structure>
				<field value=\"UINT\" />
			</structure>
        </buffer>    
        <buffer name=\"primitivesBuffer$m\" >
            <file name=\"$basename.$m.primitives.buf\"/>
            <DIM x=${primitives_count[$m]} y=1 z=1 />
			<structure>
				<field value=\"UINT\" />
			</structure>
        </buffer>
        <buffer name=\"meshletsBuffer$m\" >
            <file name=\"$basename.$m.meshlets.buf\"/>
            <DIM x=${meshlets_count[$m]} y=1 z=1 />
			<structure>
				<field value=\"UINT\" />
			</structure>
        </buffer>"
    done

   mlib_str+="
    </buffers>	

	<materials>"

    for m in "${!indices_count[@]}"
    do
        mlib_str+="
        <material name=\"mat$m\">

            <buffers>
                <buffer name=\"verticesBuffer\">
					<TYPE value=\"SHADER_STORAGE\" />
    				<BINDING_POINT value=\"1\" />
                </buffer>
                <buffer name=\"normalsBuffer\">
					<TYPE value=\"SHADER_STORAGE\" />
    				<BINDING_POINT value=\"2\" />
                </buffer>
                <buffer name=\"texcoordsBuffer\">
					<TYPE value=\"SHADER_STORAGE\" />
    				<BINDING_POINT value=\"3\" />
				</buffer>
				<buffer name=\"indicesBuffer$m\">
					<TYPE value=\"SHADER_STORAGE\" />
    				<BINDING_POINT value=\"4\" />
                </buffer>
				<buffer name=\"primitivesBuffer$m\">
					<TYPE value=\"SHADER_STORAGE\" />
    				<BINDING_POINT value=\"5\" />
				</buffer>
				<buffer name=\"meshletsBuffer$m\">
					<TYPE value=\"SHADER_STORAGE\" />
    				<BINDING_POINT value=\"6\" />
				</buffer>
            </buffers>
            "

        if [ ! -z "${textures[$m]}" ] 
        then

            mlib_str+="
            <textures>
                <texture name=\"tex$m\" UNIT=0 />
            </textures>
	        
            <shader name=\"meshTexShaders\" >
				<values>
                    <valueof uniform=\"tex\"
                             type=\"TEXTURE_BINDING\" context=\"CURRENT\"
                             component=\"UNIT\" id=0 />
            "

        else 
            
            mlib_str+="
            <shader name=\"meshColorShaders\" >
				<values>
                    <valueof uniform=\"diffuse\"
                             type=\"RENDERER\" context=\"CURRENT\"
                             component=\"DIFFUSE_$m\" />
            "
        fi

        mlib_str+="
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


    mlib_str+="
	</materials>
</materialLib>"

    echo "$mlib_str" > ${1}.mlib

fi

