// https://godotshaders.com/shader/vibrancy-backdrop-blurred-frosted-canvas-items/
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

uniform float blur_amount : hint_range(0.0, 5.0) = 2.0;
uniform float mix_amount : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    vec3 bg = textureLod(screen_texture, SCREEN_UV, blur_amount).rgb;
    vec4 src = COLOR;

    COLOR.rgb = mix(src.rgb, bg, mix_amount);
    COLOR.a = src.a;
}