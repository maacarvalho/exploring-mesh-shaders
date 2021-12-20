#version 330

in vec4 position;

out int instanceID;

void main () {

    instanceID = gl_InstanceID;
	gl_Position = position;

}
