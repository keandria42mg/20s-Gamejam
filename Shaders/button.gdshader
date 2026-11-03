shader_type canvas_item;

uniform float progress = -0.3;
uniform vec4 shine_color : source_color = vec4(1.0, 0.95, 0.8, 0.35);
uniform float width = 0.12;

void fragment() {
    // Diagonal band that sweeps left to right
    float d = (UV.x + UV.y * 0.35) - progress;
    float band = smoothstep(width, 0.0, abs(d));
    COLOR.rgb += shine_color.rgb * shine_color.a * band * COLOR.a;
}