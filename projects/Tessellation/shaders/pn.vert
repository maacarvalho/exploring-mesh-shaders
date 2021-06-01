#version 410

in vec4 position;
in vec4 normal;

out vec4 posV;
out vec4 normalV;

void main() {

	normalV = normal;
    posV =  position;
}



