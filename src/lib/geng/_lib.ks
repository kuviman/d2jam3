use (import "../common.ks").*;
const gl = import "../gl/gl.ks";
const ugli = import "../ugli.ks";

module:

const asset = import "./asset.ks";
const audio = import "./audio.ks";
const input = import "./input.ks";

const Vertex = newtype {
    .a_pos :: Vec2,
    .a_uv :: Vec2,
};

include_ast ugli.Vertex_derive(Vertex);

const ContextT = newtype {
    .canvas :: web.HtmlCanvasElement,
    .canvas_size :: {
        .width :: Float32,
        .height :: Float32,
    },
    .quad :: {
        .program :: ugli.Program,
        .buffer :: ugli.VertexBuffer.t[Vertex],
    },
};
const Context = @context ContextT;

const init = () -> { .geng :: ContextT, .gl :: gl.ContextT } => (
    @native (
        "(()=>{"
        + std.fs.read_file(
            std.path.dirname(__FILE__) + "/runtime.js"
        )
        + "})()"
    );
    
    let document = web.document();
    let canvas :: web.HtmlCanvasElement = document
        |> web.HtmlDocumentElement.get_element_by_id("canvas")
        |> js.unsafe_cast;
    let webgl :: web.WebGLRenderingContext = canvas
        |> web.HtmlCanvasElement.get_context("webgl")
        |> js.from_any;
    with gl.Context = webgl;
    let quad = {
        .program = (
            let vertex_shader = ugli.compile_shader(
                gl.VERTEX_SHADER,
                fetch_string("assets/shaders/quad/vertex.glsl")
            );
            let fragment_shader = ugli.compile_shader(
                gl.FRAGMENT_SHADER,
                fetch_string("assets/shaders/quad/fragment.glsl")
            );
            ugli.Program.init(vertex_shader, fragment_shader)
        ),
        .buffer = (
            let mut data :: ArrayList.t[Vertex] = ArrayList.new();
            ArrayList.push_back(
                &mut data,
                {
                    .a_pos = { -1, -1 },
                    .a_uv = { 0, 0 },
                },
            );
            ArrayList.push_back(
                &mut data,
                {
                    .a_pos = { +1, -1 },
                    .a_uv = { 1, 0 },
                },
            );
            ArrayList.push_back(
                &mut data,
                {
                    .a_pos = { +1, +1 },
                    .a_uv = { 1, 1 },
                },
            );
            ArrayList.push_back(
                &mut data,
                {
                    .a_pos = { -1, +1 },
                    .a_uv = { 0, 1 },
                },
            );
            ugli.VertexBuffer.init(&data)
        ),
    };
    let mut geng = {
        .canvas,
        .canvas_size = { .width = 1, .height = 1 },
        .quad,
    };
    (@native "Runtime.observe_canvas_size")(
        .canvas,
        .webgl,
        .handler = size => (
            geng.canvas_size = size;
        ),
    );
    {
        .geng,
        .gl = webgl,
    }
);

const canvas_size = () => (
    (@current Context).canvas_size
);

const Camera = newtype {
    .pos :: Vec2,
    .fov :: Float32,
};

const CameraUniforms = newtype {
    .view_matrix :: Mat3,
    .projection_matrix :: Mat3,
};

const CameraCtx = @context CameraUniforms;

impl CameraUniforms as module = (
    module:
    
    const init = (
        camera :: Camera,
        .framebuffer_size :: Vec2,
    ) -> CameraUniforms => (
        let view_matrix = {
            { 1, 0, -camera.pos.0 },
            { 0, 1, -camera.pos.1 },
            { 0, 0, 1 },
        };
        let aspect = framebuffer_size.0 / framebuffer_size.1;
        let projection_matrix = {
            { 2 / aspect / camera.fov, 0, 0 },
            { 0, 2 / camera.fov, 0 },
            { 0, 0, 1 },
        };
        {
            .view_matrix,
            .projection_matrix,
        }
    );
);

impl Camera as module = (
    module:
    
    const screen_to_world = (
        camera :: Camera,
        screen_pos :: Vec2,
        .framebuffer_size :: Vec2,
    ) -> Vec2 => (
        let uniforms = CameraUniforms.init(camera, .framebuffer_size);
        let gl_screen_pos = Vec2.map(
            Vec2.vdiv(screen_pos, framebuffer_size),
            x => x * 2 - 1,
        );
        # projection_matrix * view_matrix * world_pos = gl_screen_pos
        let world_pos = Mat3.mul_vec(
            Mat3.inverse(
                Mat3.mul_mat(
                    uniforms.projection_matrix,
                    uniforms.view_matrix,
                )
            ),
            { gl_screen_pos.0, gl_screen_pos.1, 1 },
        );
        { world_pos.0, world_pos.1 }
    );
);

const draw_quad = (
    .pos :: Vec2,
    .half_size :: Vec2,
    .texture :: ugli.Texture,
) => (
    draw_quad_subtexture(.pos, .half_size, .texture, .uv = Rect.UNIT);
);

const draw_quad_subtexture = (
    .pos :: Vec2,
    .half_size :: Vec2,
    .uv :: Rect,
    .texture :: ugli.Texture,
) => (
    let ctx = (@current Context);
    let camera = (@current CameraCtx);
    let program = ctx.quad.program;
    program |> ugli.Program.@"use";
    
    let mut draw_state = ugli.DrawState.init();
    let draw_state = &mut draw_state;
    
    program |> ugli.set_uniform("u_pos", pos, draw_state);
    program |> ugli.set_uniform("u_half_size", half_size, draw_state);
    (
        let { .bottom_left, .size } = uv;
        program |> ugli.set_uniform("u_uv_bottom_left", bottom_left, draw_state);
        program |> ugli.set_uniform("u_uv_size", size, draw_state);
    );
    program |> ugli.set_uniform("u_view_matrix", camera.view_matrix, draw_state);
    program |> ugli.set_uniform("u_projection_matrix", camera.projection_matrix, draw_state);
    program |> ugli.set_uniform("u_texture", texture, draw_state);
    program |> ugli.set_vertex_data_source(ctx.quad.buffer);
    gl.draw_arrays(gl.TRIANGLE_FAN, 0, 4);
);

const await_next_frame = () -> () => (
    await_animation_frame();
);

const load_texture = (path :: String, filter :: ugli.Filter) -> ugli.Texture => (
    ugli.Texture.init(load_image(path), filter)
);

const load_shader = (path :: String) -> ugli.Program => (
    let vertex_shader = ugli.compile_shader(
        gl.VERTEX_SHADER,
        fetch_string(path + "/vertex.glsl")
    );
    let fragment_shader = ugli.compile_shader(
        gl.FRAGMENT_SHADER,
        fetch_string(path + "/fragment.glsl")
    );
    ugli.Program.init(vertex_shader, fragment_shader)
);

const is_fullscreen = () -> Bool => (
    (@native "Runtime.is_fullscreen")()
);

const set_fullscreen = (full :: Bool) -> () => (
    let ctx = (@current Context);
    (@native "Runtime.set_fullscreen")(.canvas = ctx.canvas, .full)
);

const toggle_fullscreen = () => (
    set_fullscreen(not is_fullscreen());
);
