shader_type canvas_item;

uniform vec4 color_a : source_color = vec4(0.14, 0.10, 0.08, 1.0);
uniform vec4 color_b : source_color = vec4(0.22, 0.16, 0.12, 1.0);
uniform vec2 tiles = vec2(16.0, 9.0);
uniform vec2 speed = vec2(0.4, 0.4);

void fragment() {
    vec2 uv = UV * tiles + TIME * speed;
    float check = mod(floor(uv.x) + floor(uv.y), 2.0);
    COLOR = mix(color_a, color_b, check);
}