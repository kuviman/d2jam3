precision highp float;

attribute vec2 a_pos;
attribute vec2 a_uv;
attribute vec4 a_color;

varying vec4 v_color;
varying vec2 v_uv;

uniform mat3 u_model_matrix;
uniform mat3 u_view_matrix;
uniform mat3 u_projection_matrix;
uniform vec2 u_uv_bottom_left;
uniform vec2 u_uv_size;

vec2 rotate(vec2 v, float a) {
    float s = sin(a);
    float c = cos(a);
    return vec2(v.x * c - v.y * s, v.x * s + v.y * c);
}

void main() {
    v_uv = u_uv_bottom_left + a_uv * u_uv_size;
    v_color = a_color;
    vec3 screen_pos = u_projection_matrix
        * u_view_matrix
        * u_model_matrix
        * vec3(a_pos, 1.0);
    gl_Position = vec4(screen_pos.xy, 0.0, screen_pos.z);
}