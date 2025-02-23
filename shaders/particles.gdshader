shader_type canvas_item;

uniform float particle_density = 0.3;
uniform float particle_speed = 0.05;
uniform vec4 particle_color : source_color = vec4(0.4, 0.3, 0.8, 0.3);

float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

// Smoothstep noise for softer particles
float smoothNoise(vec2 uv) {
    vec2 lv = fract(uv);
    vec2 id = floor(uv);
    
    lv = lv * lv * (3.0 - 2.0 * lv);
    
    float bl = random(id);
    float br = random(id + vec2(1.0, 0.0));
    float tl = random(id + vec2(0.0, 1.0));
    float tr = random(id + vec2(1.0, 1.0));
    
    float t = mix(tl, tr, lv.x);
    float b = mix(bl, br, lv.x);
    
    return mix(b, t, lv.y);
}

void fragment() {
    vec2 uv = UV * 3.0;  // Scale UV for larger particles
    float particles = 0.0;
    
    // Create multiple layers of particles
    for(float i = 0.0; i < 3.0; i++) {
        // Create wispy movement
        vec2 offset = vec2(
            sin(TIME * particle_speed + i * 1.5) * 0.3 + cos(TIME * particle_speed * 0.5 + i) * 0.2,
            cos(TIME * particle_speed + i * 1.5) * 0.3 + sin(TIME * particle_speed * 0.5 + i) * 0.2
        );
        
        // Add some swirling
        float angle = length(uv - vec2(0.5)) * 2.0 + TIME * particle_speed * 0.5;
        offset += vec2(cos(angle), sin(angle)) * 0.1;
        
        // Create smoother noise
        float noise = smoothNoise((uv + offset) * (1.0 + i * 0.5));
        
        // Shape the particles
        float particle = smoothstep(1.0 - particle_density * 0.5, 1.0, noise);
        particle *= smoothstep(0.0, 0.4, particle);  // Softer edges
        
        // Add trail effect
        particle *= 1.0 - length(uv - vec2(0.5 + offset.x, 0.5 + offset.y)) * 0.5;
        
        particles += particle * (1.0 - i * 0.3);  // Fade out higher layers
    }
    
    // Add glow effect
    vec4 glow = particle_color;
    glow.a *= particles * 0.5;
    
    // Smooth blend
    COLOR = mix(vec4(0.0), glow, smoothstep(0.0, 1.0, glow.a));
}