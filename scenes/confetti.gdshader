shader_type canvas_item;

uniform float speed : hint_range(0.0, 10.0) = 2.0;

// Simple hash function
float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

void fragment() {
    // Use the particle's original COLOR.r as a seed
    float seed = COLOR.r * 100.0;

    // Generate a "random" hue for this particle
    float hue = hash(seed);

    // Optionally, you can make it slowly cycle over time
    hue = fract(hue + TIME * 0.1 * speed);

    float sat = 1.0;
    float val = 1.0;

    // HSV -> RGB
    vec3 rgb = clamp(abs(mod(hue * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
    rgb = val * mix(vec3(1.0), rgb, sat);

    COLOR = vec4(rgb, 1.0);
}
