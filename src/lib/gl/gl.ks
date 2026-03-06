const js = import "../js.ks";
const web = import "../web.ks";

@syntax "js_call" 30 @wrap never = "@js_call" " " js _=(@wrap if_any "(" ""/"\n\t" args:any ""/"\\\n" ")");
impl syntax (@js_call js(args)) = `(
    (@native ("async(ctx,...args)=>{return await(" + $js + ")(...args)}"))($args)
);
@syntax "js_call_method" 30 @wrap never = "@js_call" " " obj "." js _=(@wrap if_any "(" ""/"\n\t" args:any ""/"\\\n" ")");
impl syntax (@js_call obj.js(args)) = `(
    (@native ("async(ctx,o,...args)=>{return await o." + $js + "(...args)}"))($obj, ...{ $args })
);

module:

include "./types.ks";
include "./constants.ks";

const ContextT = web.WebGLRenderingContext;
const Context = @context ContextT;

const clear = (bits :: GLbitfield) -> () => (
    let ctx = (@current Context);
    @js_call ctx."clear"(bits)
);

const clear_color = (
    r :: GLclampf,
    g :: GLclampf,
    b :: GLclampf,
    a :: GLclampf,
) -> () => (
    let ctx = (@current Context);
    @js_call ctx."clearColor"(r, g, b, a)
);

const create_shader = (shader_type :: GLenum) -> Option.t[Shader] => (
    let ctx = (@current Context);
    @js_call ctx."createShader"(shader_type)
        |> js.check_null
);

const shader_source = (
    shader :: Shader,
    source :: String,
) -> () => (
    let ctx = (@current Context);
    @js_call ctx."shaderSource"(shader, source)
);

const compile_shader = (shader :: Shader) -> () => (
    let ctx = (@current Context);
    @js_call ctx."compileShader"(shader)
);

const get_shader_parameter_bool = (
    shader :: Shader,
    pname :: GLenum,
) -> GLboolean => (
    let ctx = (@current Context);
    @js_call ctx."getShaderParameter"(shader, pname)
);

const get_shader_info_log = (shader :: Shader) -> String => (
    let ctx = (@current Context);
    @js_call ctx."getShaderInfoLog"(shader)
);

const create_program = () -> Option.t[Program] => (
    let ctx = (@current Context);
    @js_call ctx."createProgram"()
        |> js.check_null
);

const attach_shader = (
    program :: Program,
    shader :: Shader,
) -> () => (
    let ctx = (@current Context);
    @js_call ctx."attachShader"(program, shader)
);

const link_program = (program :: Program) -> () => (
    let ctx = (@current Context);
    @js_call ctx."linkProgram"(program)
);

const get_program_parameter_bool = (
    program :: Program,
    pname :: GLenum,
) -> GLboolean => (
    let ctx = (@current Context);
    @js_call ctx."getProgramParameter"(program, pname)
);

const get_program_parameter_int = (
    program :: Program,
    pname :: GLenum,
) -> GLint => (
    let ctx = (@current Context);
    @js_call ctx."getProgramParameter"(program, pname)
);

const get_program_info_log = (program :: Program) -> String => (
    let ctx = (@current Context);
    @js_call ctx."getProgramInfoLog"(program)
);

const use_program = (program :: Program) -> () => (
    let ctx = (@current Context);
    @js_call ctx."useProgram"(program)
);

const draw_arrays = (
    mode :: GLenum,
    first :: GLint,
    count :: GLsizei,
) -> () => (
    let ctx = (@current Context);
    @js_call ctx."drawArrays"(mode, first, count)
);

const create_buffer = () -> Buffer => (
    let ctx = (@current Context);
    @js_call ctx."createBuffer"()
);

const bind_buffer = (
    target :: GLenum,
    buffer :: Buffer,
) -> () => (
    let ctx = (@current Context);
    @js_call ctx."bindBuffer"(target, buffer)
);

const buffer_data = (
    target :: GLenum,
    src_data :: js.Any,
    usage :: GLenum,
) -> () => (
    let ctx = (@current Context);
    @js_call ctx."bufferData"(target, src_data, usage)
);

const vertex_attrib_pointer = (
    index :: GLuint,
    size :: GLint,
    @"type" :: GLenum,
    normalized :: GLboolean,
    stride :: GLsizei,
    offset :: GLintptr,
) -> () => (
    let ctx = (@current Context);
    @js_call ctx."vertexAttribPointer"(
        index, size, @"type", normalized, stride, offset
    )
);

const enable = (cap :: GLenum) -> () => (
    let ctx = (@current Context);
    @js_call ctx."enable"(cap)
);

const blend_color = (
    red :: GLclampf,
    green :: GLclampf,
    blue :: GLclampf,
    alpha :: GLclampf,
) -> () => (
    let ctx = (@current Context);
    @js_call ctx."blendColor"(red, green, blue, alpha)
);

const blend_func = (src_factor :: GLenum, dst_factor :: GLenum) -> () => (
    let ctx = (@current Context);
    @js_call ctx."blendFunc"(src_factor, dst_factor)
);

const blend_func_separate = (
    src_rgb :: GLenum,
    dst_rgb :: GLenum,
    src_alpha :: GLenum,
    dst_alpha :: GLenum,
) -> () => (
    let ctx = (@current Context);
    @js_call ctx."blendFuncSeparate"(src_rgb, dst_rgb, src_alpha, dst_alpha)
);

const blend_equation = (mode :: GLenum) -> () => (
    let ctx = (@current Context);
    @js_call ctx."blendEquation"(mode)
);

const blend_equation_separate = (
    mode_rgb :: GLenum,
    mode_alpha :: GLenum,
) -> () => (
    let ctx = (@current Context);
    @js_call ctx."blendEquationSeparate"(mode_rgb, mode_alpha)
);

# blendEq(src * srcFactor, dst * dstFactor)
const enable_vertex_attrib_array = (index :: GLuint) -> () => (
    let ctx = (@current Context);
    @js_call ctx."enableVertexAttribArray"(index)
);

const disable_vertex_attrib_array = (index :: GLuint) -> () => (
    let ctx = (@current Context);
    @js_call ctx."disableVertexAttribArray"(index)
);

const get_active_attrib = (
    program :: Program,
    index :: GLuint,
) -> ActiveInfo => (
    let ctx = (@current Context);
    @js_call ctx."getActiveAttrib"(program, index)
);

const get_active_uniform = (
    program :: Program,
    index :: GLuint,
) -> ActiveInfo => (
    let ctx = (@current Context);
    @js_call ctx."getActiveUniform"(program, index)
);

const get_uniform_location = (
    program :: Program,
    name :: String,
) -> Option.t[WebGLUniformLocation] => (
    let ctx = (@current Context);
    @js_call ctx."getUniformLocation"(program, name)
        |> js.check_null
);

const create_texture = () -> WebGLTexture => (
    let ctx = (@current Context);
    @js_call ctx."createTexture"()
);

const bind_texture = (
    target :: GLenum,
    texture :: WebGLTexture,
) -> WebGLTexture => (
    let ctx = (@current Context);
    @js_call ctx."bindTexture"(target, texture)
);

const tex_image_2d = (
    target :: GLenum,
    level :: GLint,
    internal_format :: GLenum,
    format :: GLenum,
    @"type" :: GLenum,
    source :: js.Any,
) -> WebGLTexture => (
    let ctx = (@current Context);
    @js_call ctx."texImage2D"(target, level, internal_format, format, @"type", source)
);

const tex_parameter_i = (
    target :: GLenum,
    pname :: GLenum,
    param :: GLint,
) -> WebGLTexture => (
    let ctx = (@current Context);
    @js_call ctx."texParameteri"(target, pname, param)
);

const tex_parameter_f = (
    target :: GLenum,
    pname :: GLenum,
    param :: GLfloat,
) -> WebGLTexture => (
    let ctx = (@current Context);
    @js_call ctx."texParameterf"(target, pname, param)
);

const generate_mipmap = (target :: GLenum) -> () => (
    let ctx = (@current Context);
    @js_call ctx."generateMipmap"(target)
);

const pixel_store_bool = (
    pname :: GLenum,
    value :: GLboolean,
) -> () => (
    let ctx = (@current Context);
    @js_call ctx."pixelStorei"(pname, value)
);

const Shader = @opaque_type;
const Program = @opaque_type;
const Buffer = @opaque_type;
const ActiveInfo = newtype {
    .name :: String,
    .size :: GLsizei,
    .@"type" :: GLenum,
};
const WebGLUniformLocation = @opaque_type;
const WebGLTexture = @opaque_type;
