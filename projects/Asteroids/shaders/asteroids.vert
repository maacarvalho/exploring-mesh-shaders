#version 410

in vec4 position;

uniform mat4 m_model;

void main() {

    gl_Position = m_model * position;

}