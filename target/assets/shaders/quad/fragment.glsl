precision highp float;

varying vec2 v_uv;

uniform sampler2D u_texture;
uniform vec4 u_color;

void main() {
    gl_FragColor = texture2D(u_texture, v_uv) * u_color;
}