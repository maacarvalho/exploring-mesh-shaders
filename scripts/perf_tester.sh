#!/usr/bin/bash

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
            material_names[$mat]=$(awk "/^$mat/ {printf \$2}" ${1}.materials.buf)
            diffuse_colors[$mat]=$(awk "/^$mat/ {printf \"x=\\\"%s\\\" y=\\\"%s\\\" z=\\\"%s\\\"\", \$3, \$4, \$5}" ${1}.materials.buf)
            if [[ ! -z "$(awk "/^$mat/ {print \$6}" ${1}.materials.buf)" ]] 
            then
                textures[$mat]=$(awk "/^$mat/ {print \$6}" ${1}.materials.buf)
            fi
        else
            break
        fi
        
        material_count+=1 
    done
}


## Configures a Mesh Shader pipeline
configure_mesh_pipelines () {

    for locs in "${local_size[@]}"
    do

    ## --------------------------------------- Pipelines ---------------------------------------
        pipelines_str+="
        <pipeline name=\"Mesh_${locs}_${maxv}_${maxp}\" default=\"true\" frameCount = 500>
            <preScript file=\"scripts/times.$locs.$maxv.$maxp.lua\" script=\"startTimer_${locs}_${maxv}_${maxp}\" />"
        
        for m in "${!indices_count[@]}"
        do
            pipelines_str+="
            <pass class=\"mesh\" name=\"meshPass_${locs}_${maxv}_${maxp}_$m\">
                <camera name=\"objCamera\" />
                <lights>
                    <light name=\"objLight\" />
                </lights>
                <material name=\"meshMat_${locs}_${maxv}_${maxp}_$m\" fromLibrary=\"objMatLib\" count=\"${meshes_count[$m]}\" />
            </pass>"
        done

        pipelines_str+="
            <postScript file=\"scripts/times.$locs.$maxv.$maxp.lua\" script=\"stopTimer_${locs}_${maxv}_${maxp}\" />
        </pipeline>"


        ## --------------------------------------- Shaders ---------------------------------------
        shaders_str+="
        <shader name=\"meshColor_${locs}_${maxv}_${maxp}\"       ms = \"shaders/obj.$locs.$maxv.$maxp.mesh\" 
                                                 ps = \"shaders/objDiffuse.frag\" />"
        if [ ! "${#textures[@]}" -eq 0 ] 
        then
            shaders_str+="
        <shader name=\"meshTex_${locs}_${maxv}_${maxp}\" 	        ms = \"shaders/obj.$locs.$maxv.$maxp.mesh\" 
                                                 ps = \"shaders/objTex.frag\" />"
        fi


    ## --------------------------------------- Materials ---------------------------------------
        for m in "${!indices_count[@]}"
        do
        materials_str+="
        <material name=\"meshMat_${locs}_${maxv}_${maxp}_$m\">

            <buffers>
                <buffer name=\"verticesBuffer_${maxv}_${maxp}\">
                    <TYPE value=\"SHADER_STORAGE\" />
                    <BINDING_POINT value=\"1\" />
                </buffer>
                <buffer name=\"normalsBuffer_${maxv}_${maxp}\">
                    <TYPE value=\"SHADER_STORAGE\" />
                    <BINDING_POINT value=\"2\" />
                </buffer>"


        if [ ! -z "${textures[$m]}" ]
        then
            materials_str+="
                <buffer name=\"texcoordsBuffer_${maxv}_${maxp}\">
                    <TYPE value=\"SHADER_STORAGE\" />
                    <BINDING_POINT value=\"3\" />
                </buffer>"
        fi

        materials_str+="
                <buffer name=\"indicesBuffer_${maxv}_${maxp}_$m\">
                    <TYPE value=\"SHADER_STORAGE\" />
                    <BINDING_POINT value=\"4\" />
                </buffer>
                <buffer name=\"primitivesBuffer_${maxv}_${maxp}_$m\">
                    <TYPE value=\"SHADER_STORAGE\" />
                    <BINDING_POINT value=\"5\" />
                </buffer>
                <buffer name=\"meshletsBuffer_${maxv}_${maxp}_$m\">
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
            
            <shader name=\"meshTex_${locs}_${maxv}_${maxp}\" >
                <values>
                    <valueof uniform=\"tex\"
                             type=\"TEXTURE_BINDING\" context=\"CURRENT\"
                             component=\"UNIT\" id=0 />
            "

        else 
            
            materials_str+="
            <shader name=\"meshColor_${locs}_${maxv}_${maxp}\" >
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

    done


    ## --------------------------------------- Attributes ---------------------------------------
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

    
    ## --------------------------------------- Textures ---------------------------------------
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

    
    ## --------------------------------------- Buffers ---------------------------------------
    buffers_str+="
        <buffer name=\"verticesBuffer_${maxv}_${maxp}\" >
            <file name=\"$folder/$basename.vertices.buf\"/>
            <DIM x=$vertices_count y=1 z=1 />
			<structure>
				<field value=\"FLOAT\" />
			</structure>
		</buffer>
        <buffer name=\"normalsBuffer_${maxv}_${maxp}\" >
            <file name=\"$folder/$basename.normals.buf\"/>
            <DIM x=$normals_count y=1 z=1 />
			<structure>
				<field value=\"FLOAT\" />
			</structure>
		</buffer>"

    
    if [ ! "${#textures[@]}" -eq 0 ] 
    then
        buffers_str+="
        <buffer name=\"texcoordsBuffer_${maxv}_${maxp}\" >
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
        <buffer name=\"indicesBuffer_${maxv}_${maxp}_$m\" >
            <file name=\"$folder/$basename.$m.indices.buf\"/>
            <DIM x=${indices_count[$m]} y=1 z=1 />
			<structure>
				<field value=\"UINT\" />
			</structure>
        </buffer>    
        <buffer name=\"primitivesBuffer_${maxv}_${maxp}_$m\" >
            <file name=\"$folder/$basename.$m.primitives.buf\"/>
            <DIM x=${primitives_count[$m]} y=1 z=1 />
			<structure>
				<field value=\"UINT\" />
			</structure>
        </buffer>
        <buffer name=\"meshletsBuffer_${maxv}_${maxp}_$m\" >
            <file name=\"$folder/$basename.$m.meshlets.buf\"/>
            <DIM x=${meshlets_count[$m]} y=1 z=1 />
			<structure>
				<field value=\"UINT\" />
			</structure>
        </buffer>"
    done

}



## Configures a Traditional Pipeline
configure_traditional_pipeline () {


    ## --------------------------------------- Scenes ---------------------------------------
    scenes_str+="
            <scene name=\"objScene\" type=\"Scene\">
                <file name=\"$basename\"/>
            </scene>"


    ## --------------------------------------- Pipelines ---------------------------------------
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
                <materialMaps>"

    for m in "${!material_names[@]}"
    do
        pipelines_str+="
					<map fromMaterial=\"${material_names[$m]}\"  	toLibrary=\"objMatLib\" 	toMaterial=\"tradMat_$m\" />"
    done
    
    pipelines_str+="
                </materialMaps>
            </pass>
            <postScript file=\"scripts/times.0.0.0.lua\" script=\"stopTimer_0_0_0\" />
        </pipeline>"
 

    ## --------------------------------------- Attributes ---------------------------------------
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

    
    ## --------------------------------------- Textures ---------------------------------------
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

    ## --------------------------------------- Shaders ---------------------------------------
    if [ ! "${#textures[@]}" -eq 0 ] 
    then
        shaders_str+="
        <shader name=\"tradTex\" 	                  vs = \"shaders/objTrad.vert\" 
										            ps = \"shaders/objTex.frag\" />"
    fi

    shaders_str+="
        <shader name=\"tradColor\"                    vs = \"shaders/objTrad.vert\" 
										            ps = \"shaders/objDiffuse.frag\" />"


    ## --------------------------------------- Materials ---------------------------------------
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

## Creates a script to run all .nau files
create_runner_script () {

    echo "#!/usr/bin/bash

project_files=\$(ls | awk '/.nau/ {print \$0}')

for proj in \$project_files
do 
    
    echo \"Running: \$proj\"

    # Running Nau project
    cmd.exe /C start \$proj

    # Waiting for Nau project to finish
    while [[ ! -z \$(tasklist.exe | awk '/composerImGui/ {print \$0}') ]]
    do
        sleep 1
    done

done"

}


## Resets current project 
reset_proj () {

    attributes_str=""
    buffers_str=""
    materials_str=""
    mlibs_str=""
    pipelines_str=""
    scenes_str=""
    shaders_str=""
    textures_str=""

}


## Main
if [ $# -ne 1 ] 
then

    echo "Illegal number of parameters" >&2
    exit 1

else

    source proj_helper.sh

    filepath=$1
    dirname=$(dirname $filepath)
    basename=$(basename $filepath)

    max_vertices=( 256 128 64 32 16 8 )
    max_primitives=( 512 256 128 64 32 16 8 )
    local_size=( 32 16 8 )
    #max_vertices=( 32 )
    #max_primitives=( 128 )
    #local_size=( 32 16 )

    declare vertices_count
    declare normals_count
    declare texcoords_count
    declare -A indices_count
    declare -A primitives_count
    declare -A meshlets_count
    declare -A meshes_count
    declare -A material_names
    declare -A diffuse_colors
    declare -A textures

    reset_proj

    # Creating folder structure
    [[ ! -d "$dirname/buffers" ]] && mkdir "$dirname/buffers"
    [[ ! -d "$dirname/shaders" ]] && mkdir "$dirname/shaders"
    [[ ! -d "$dirname/scripts" ]] && mkdir "$dirname/scripts"

    for maxv in "${max_vertices[@]}"
    do
        for maxp in "${max_primitives[@]}" 
        do
            
            # Folder for the buffers of this specific confirguration
            folder=$(printf "buffers/%03d_%03d" $maxv $maxp)
            [[ ! -d $dirname/$folder ]] && mkdir $dirname/$folder

            # Converting .obj to buffers if necessary
            if [[ ! -f "$dirname/$folder/$basename.vertices.buf" ]]
            then
                
                # Creating buffers
                lua obj_converter.lua -mv $maxv -mp $maxp -nm $filepath 

                # Copying buffers to folder
                mv $filepath.*.buf $dirname/$folder

            fi

            # Getting information on the materials of the mesh
            measure_buffers "$dirname/$folder/$basename"

            # Creating mesh shader
            for locs in "${local_size[@]}"
            do
                # Creating mesh shader
                [[ ! -f "$dirname/shaders/obj.$locs.$maxv.$maxp.mesh" ]] && create_mesh_shader > "$dirname/shaders/obj.$locs.$maxv.$maxp.mesh"

                # Creating lua script for performance measuring
                [[ ! -f "$dirname/scripts/times.$locs.$maxv.$maxp.lua" ]] && create_timer_lua_script > "$dirname/scripts/times.$locs.$maxv.$maxp.lua"
            done

            # Configure mesh pipelines
            configure_mesh_pipelines
            
            # Creating project
            create_mlib > $filepath.$maxv.$maxp.mlib
            create_proj > $filepath.$maxv.$maxp.nau

            # Clearing project settings
            reset_proj
        done
    done

    # Creating remainder shaders
    [[ ! -f "$dirname/shaders/objTrad.vert" ]] && create_vert_shader > "$dirname/shaders/objTrad.vert"
    [[ ! -f "$dirname/shaders/objTex.frag" ]] && [[ ! -z "$texcoords_count" ]] && create_tex_frag_shader > "$dirname/shaders/objTex.frag"
    [[ ! -f "$dirname/shaders/objDiffuse.frag" ]] && create_diffuse_frag_shader > "$dirname/shaders/objDiffuse.frag"

    # Creating project for the traditional pipeline
    locs=0
    maxv=0
    maxp=0

    # Creating lua script for performance measuring
    [[ ! -f "$dirname/scripts/times.$locs.$maxv.$maxp.lua" ]] && create_timer_lua_script > "$dirname/scripts/times.$locs.$maxv.$maxp.lua"

    configure_traditional_pipeline
    
    create_proj > $filepath.$maxv.$maxp.nau
    create_mlib > $filepath.$maxv.$maxp.mlib

fi
