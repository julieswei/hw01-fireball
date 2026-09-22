#version 300 es

precision highp float;

in vec4 vs_Pos;

out vec2 fs_UV;

void main() {
    // convert space
    fs_UV = (vs_Pos.xy + 1.0) * 0.5;

    // draw on screen in screen space, 0.999 far away as possible
    gl_Position = vec4(vs_Pos.xy, 0.999, 1.0);
}