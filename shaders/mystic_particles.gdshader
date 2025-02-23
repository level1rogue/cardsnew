shader_type canvas_item;
render_mode blend_add;

uniform float time;

float random(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float particle(vec2 uv, vec2 pos, float size) {
    float d = length(uv - pos);
    float core = smoothstep(size * 0.2, 0.0, d);  // Reduced from 2.0 to 0.2
    float glow = size * 0.5 / d;  // Reduced from 5.0 to 0.5
    return core + glow * 0.3;  // Reduced from 0.8 to 0.3
}

void fragment() {
    vec2 uv = UV;
    vec4 color = texture(TEXTURE, uv);
    
    // Darker, mystical color tint
    float r = color.r * 0.3 + color.g * 0.2 + color.b * 0.3;
    float g = color.r * 0.2 + color.g * 0.3 + color.b * 0.3;
    float b = color.r * 0.4 + color.g * 0.4 + color.b * 0.5;
    
    // Mystical fog with more variation
    float fog = random(uv + time * 0.05) * 0.08;
    
    // Vignette
    float vignette = 1.0 - distance(uv, vec2(0.5, 0.5));
    vignette = pow(vignette, 2.0);
    vignette = smoothstep(0.0, 0.6, vignette);

    // Chaotic particle system
    float particles = 0.0;
    for(float i = 0.0; i < 25.0; i++) {
        vec2 pos = vec2(
          fract(random(vec2(i, 1.0)) + sin(time * 0.02 + random(vec2(i, 4.0)) * 0.02)),
          fract(random(vec2(i, 2.0)) + cos(time * 0.01 + random(vec2(i, 5.0)) * 0.02))
        );
        
        float windStrength = sin(time * 0.1) * 0.1;
        pos.x += sin(pos.y * 4.0 + time * 0.2) * windStrength;
        pos.y += cos(pos.x * 3.0 + time * 0.15) * 0.05;
        
        float size = random(vec2(i, 3.0)) * 0.01 + 0.0004; 

        float intensity = (sin(time + i) * 0.5 + 0.5) * 1.2;
        particles += particle(uv, pos, size) * intensity;
    }

    vec3 mystical = vec3(r, g, b);
    mystical += fog;
    mystical *= vignette;
    
    vec3 particleColor = vec3(0.7, 0.5, 1.0);
    vec3 particleColor2 = vec3(0.4, 0.6, 1.0);
    vec3 finalParticleColor = mix(particleColor, particleColor2, sin(time) * 0.5 + 0.5);
    mystical += particles * finalParticleColor * 1.8;
    
    mystical *= 0.15;  // Make it more transparent
    
    float darkness = (1.0 - (mystical.r + mystical.g + mystical.b) / 3.0);
    mystical.b += darkness * 0.15;
    
    // Make the shader partially transparent
    COLOR = vec4(mystical, 0.3);  // Set alpha to 0.5 for partial transparency
}