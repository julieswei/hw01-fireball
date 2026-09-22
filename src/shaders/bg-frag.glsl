#version 300 es

precision highp float;

uniform float u_Time;

in vec2 fs_UV;

out vec4 out_Col;

void main() {
    vec3 bottomColor = vec3(0.03, 0.02, 0.08);
    vec3 topColor = vec3(0.10, 0.04, 0.18);

    // vertical purpl-ish grayish gradient
    vec3 color = mix(bottomColor, topColor, fs_UV.y * 1.6);

    // magic glow around center UV
    // Very subtle animated magical glow, the center itself floats around
    // center (x, y) x, float left to right and back, gently
    vec2 center = vec2(0.5 + sin(u_Time * 0.2) * 0.08, 0.55);

    // further away from center^ = less glow
    float dist = distance(fs_UV, center);
    float glow = 1.0 - smoothstep(0.0, 0.5, dist);

    vec3 glowColor = vec3(0.788, 0.667, 0.82);
    //vec3 glowColor = vec3(0.247, 0.224, 0.278);

    
    float pulse = 0.85 + 0.15 * sin(u_Time * 0.8);

    // bottom hazy things
    float bottomHaze = 1.0 - smoothstep(0.0, 0.7, fs_UV.y);

    vec3 greenHaze = vec3(0.05, 0.18, 0.10);

    color += greenHaze * bottomHaze;

    color += glowColor * glow * 0.5 * pulse;

    out_Col = vec4(color, 1.0);
}