shader_type spatial;

render_mode blend_mix, depth_draw_always, cull_back;

uniform float effect_strength : hint_range(0.0, 1.0) = 0.0;

uniform float cutoff_local_y = 0.0;
uniform float height_fade_softness = 0.25;

uniform sampler2D albedo_texture : source_color;
uniform vec4 albedo_color : source_color = vec4(1.0);

varying float local_y;

// https://godotshaders.com/shader/bayer-dithering/
const mat4 bayer_index = mat4(
    vec4(00.0/16.0, 12.0/16.0, 03.0/16.0, 15.0/16.0),
    vec4(08.0/16.0, 04.0/16.0, 11.0/16.0, 07.0/16.0),
    vec4(02.0/16.0, 14.0/16.0, 01.0/16.0, 13.0/16.0),
    vec4(10.0/16.0, 06.0/16.0, 09.0/16.0, 05.0/16.0));


void vertex() {
	local_y = VERTEX.y;
}

void fragment() {
	vec4 tex_color = texture(albedo_texture, UV) * albedo_color;

	float height_mask = smoothstep(
		cutoff_local_y - height_fade_softness,
		cutoff_local_y + height_fade_softness,
		local_y
	);

	float cut_amount = height_mask * effect_strength;
	// find bayer matrix entry based on fragment position
	float dither_value = bayer_index[int(FRAGCOORD.x) % 4][int(FRAGCOORD.y) % 4];

    // https://godotshaders.com/shader/section-analysis-profile-cutout-from-the-bottom-up/
	if (dither_value < cut_amount) {
		discard;
	}

	ALBEDO = tex_color.rgb;
	ALPHA = tex_color.a;
}