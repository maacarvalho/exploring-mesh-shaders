# Exploring Mesh Shaders

This repository contains the source code developed during the development of the Master's Thesis "Exploring Mesh Shaders". 

This repository is divided into three folders:
- Renderer
- Scripts
- Projects

## Renderer

The renderer folder links to the **Nau3D** engine's repository, which was used throughout the thesis. This rendered is needed to run the projects present in this repository. 

## Scripts

The scripts folder contains several scripts developed to assist with different aspects of working with mesh shaders. Some of these scripts are written in Bash but are intended to be run in a Windows Subsystem Environment.

- Battery Status
	> The battery_status.sh bash script runs indefinitely and prints a message when the laptop is disconnected from its power source. This was made to ensure that, while performance tests were being executed, the laptop wasn't running on battery. 
	
	> To run this script: **bash battery_status.sh**
	
- Meshlet Analyser
	> The meshlet_analyser.py python script was designed for the analysis of the *meshlets* created for the various projects. This script reads the buffer files relating to the *meshlets* and outputs a **.csv** file containing the number of *meshlets*, the minimum, average and maximum amount of primitives in those *meshlets* and their average miss ratio. These statistics are useful to evaluate the vertex reuse of the *meshlets*.

	> To run this script: **python meshlet_analyser.py \<project_folder\>/analysis.csv**. The **\<project_folder\>** must follow the structure created by the **nau_project_creator.sh** script.
	
- Nau Project Creator
	 > The nau_project_creator.sh bash script creates **.nau** project files for *Wavefront* models. These created projects contain both a traditional and at least one mesh pipeline capable of rendering the chosen 3D model.
	 
	 > To run this script: **bash nau_project_creator.sh \<project_folder\>/model.obj**. To choose the **local_size**, **max_vertices** and **max_primitives** values that will be used for the mesh shaders and the *meshlets* generation, the lines 538-540 should be changed. It's possible that after the project creation, the models cannot be seen when running the **.nau** file, as the camera position is not chosen depending on the model's size and position and must be changed manually.
	 
- Obj Converter
	> The obj_converter.lua script converts *Wavefront* models into several files which can be read directly to buffers. This script is used by the Nau Project Creator script during the project creation.

	>To run this script: **lua obj_converter.lua [-nn] [-nm] -mv \<max_vertices\> -mp \<max_primitives\> \<project_folder\>/model.obj**. For the creation the 3D model into *meshlets*, the script must receive the maximum amount of vertices and primitives each *meshlet* can have. Additionally, if desired, the flags **-nn** and **-nm** can be used to ignore the **normals** and **material properties** of the 3D model during the conversion.

- Obj Randomizer
	> The obj_randomizer.sh script randomizes the order of the primitives in a *Wavefront* model. This is useful for analysing how much the primitive ordering impacts the final performance of the model in the different pipelines.

	> To run this script: **bash obj_randomizer.sh \<project_folder\>/model.obj**. This command does not change the order in place and instead generates as output a **model.rand.obj** file in the same folder as the original model.

## Projects

The projects folder contains four different projects developed during this thesis:

- Cube
	 >  The cube project serves as the tutorial for development with mesh shaders.  The triviality of this project should facilitate the process of understanding how mesh shaders function.

- Grass Blades
	> The grass_blades project is intended as the comparison of mesh shaders and the traditional geometry shaders. To do this comparison, each was tasked with procedurally generating grass blades. This project was developed by forking a project present in the Nau3D's repository.

- Tessellation 
	> The tessellation project represents the comparison of mesh shaders and the traditional tessellation shaders. To do this comparison, a tessellation algorithm, which mimics the behaviour of the tessellation shaders (for *even_spacing* tessellation), was written for mesh shaders. 

- Sports Car
	> The sports_car project is intended as an example of the comparison of the mesh pipeline and the traditional pipeline when rendering 3D models.

- Ocean Waves
	> The ocean_waves project serves as the comparison of mesh shaders and the traditional tessellation shaders,when implemented in a real-world scenario. To do this, each was tasked with generating the waves of the ocean. This project was developed by forking a project present in the Nau3D's repository.
	
To run these projects, the **.nau** files must be run with the **Nau3D** engine. 
