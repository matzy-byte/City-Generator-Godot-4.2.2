shader_type spatial;

uniform sampler2D texture_wall;
uniform vec2 mult_uv;

varying vec3 normal;
varying vec3 position;

void vertex() {
	normal = NORMAL.xyz;
	position = VERTEX.xyz;
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec2 uv = vec2(mult_uv.x * UV.x, mult_uv.y * UV.y);
	vec4 texture_color = texture(texture_wall, uv);
	
	if (normal.y > 0.0) {
		ALBEDO = vec3(0.05, 0.05, 0.05);
	} else {
		ALBEDO = texture_color.rgb;
	}
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}

