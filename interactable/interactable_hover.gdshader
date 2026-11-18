shader_type spatial;

render_mode blend_mix, depth_draw_always, cull_back;

uniform float show_amount : hint_range(0.0, 1.0) = 1.0;
uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo_texture : source_color;

void fragment() {
	vec4 tex = texture(albedo_texture, UV) * albedo_color;

	ALBEDO = tex.rgb;
	ALPHA = tex.a * show_amount;

	if (ALPHA <= 0.01) {
		discard;
	}
}