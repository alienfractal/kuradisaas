// Shared CoolorBurn CRT treatment, adapted to Flutter's portable coordinates.
#version 460 core
#include <flutter/runtime_effect.glsl>
uniform vec2 uResolution;
uniform sampler2D uTexture;
out vec4 fragColor;
void main() {
    vec2 pos = FlutterFragCoord().xy;
    vec2 uv = pos / uResolution;
    float aberration = 0.001;
    vec3 color = vec3(
        texture(uTexture, uv + vec2(aberration, 0.0)).r,
        texture(uTexture, uv + vec2(0.0, aberration)).g,
        texture(uTexture, uv - vec2(aberration, 0.0)).b);
    color -= sin(pos.y * 2.0) * 0.05;
    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
