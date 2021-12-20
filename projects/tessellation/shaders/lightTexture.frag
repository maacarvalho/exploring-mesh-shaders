#version 410

uniform	sampler2D texUnit;

in perVertexData {

    //vec3 normalTE;
    vec2 texCoordTE;
};

out vec4 outputF;

void main() {

	outputF = texture(texUnit, texCoordTE);
}
