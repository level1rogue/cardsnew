shader_type canvas_item;

uniform float speed : hint_range(0.0, 5.0) = 0.5;
uniform float scale : hint_range(0.1, 5.0) = 2.0;
uniform float distortion_strength : hint_range(0.0, 1.0) = 0.2;
uniform vec4 color_a : source_color = vec4(0.2, 0.1, 0.3, 1.0);
uniform vec4 color_b : source_color = vec4(0.5, 0.3, 0.7, 1.0);
uniform vec4 color_c : source_color = vec4(0.8, 0.5, 0.9, 1.0);

float random(vec2 uv) {
    return fract(sin(dot(uv.xy,
        vec2(12.9898,78.233))) * 43758.5453123);
}

float noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    
    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    // Smooth interpolation
    vec2 u = f * f * (3.0 - 2.0 * f);

    // Mix 4 corners
    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

void fragment() {
    vec2 uv = UV * scale;
    float time = TIME * speed;
    
    // Create base pattern
    float n = noise(uv + time);
    n += noise(uv * 2.0 - time * 0.5) * 0.5;
    n += noise(uv * 4.0 + time * 0.25) * 0.25;
    n = n / (1.0 + 0.5 + 0.25); // Normalize
    
    // Add movement
    vec2 distorted_uv = uv;
    distorted_uv.x += sin(n * 3.14159 + time) * distortion_strength;
    distorted_uv.y += cos(n * 3.14159 + time) * distortion_strength;
    
    float final_noise = noise(distorted_uv);
    
    // Mix colors
    vec4 color;
    if (final_noise < 0.33) {
        color = mix(color_a, color_b, final_noise * 3.0);
    } else if (final_noise < 0.66) {
        color = mix(color_b, color_c, (final_noise - 0.33) * 3.0);
    } else {
        color = color_c;
    }
    
    COLOR = color;
}