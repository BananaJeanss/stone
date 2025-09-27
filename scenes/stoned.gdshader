shader_type canvas_item;

void fragment() {
    // Sample the texture at the current UV
    vec4 tex_color = texture(TEXTURE, UV);
    
    // Convert to grayscale using the luminance formula
    float gray = dot(tex_color.rgb, vec3(0.299, 0.587, 0.114));
    
    // Output the grayscale color, keep original alpha
    COLOR = vec4(vec3(gray), tex_color.a);
}
