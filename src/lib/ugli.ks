import "./js_syntax.ks";
use (import "./la.ks").*;
const js = import "./js.ks";
const web = import "./web.ks";
const gl = import "./gl/gl.ks";

use std.collections.OrdMap;

module:

const clear = (color :: Vec4) => (
    gl.clear_color(...color);
    gl.clear(gl.COLOR_BUFFER_BIT);
);

const SizedType = [Self] newtype {
    .size :: Int32,
};

impl Float32 as SizedType = {
    .size = 4,
};

const compile_shader = (shader_type, source) => (
    let shader = gl.create_shader(shader_type)
        |> Option.unwrap;
    gl.shader_source(shader, source);
    gl.compile_shader(shader);
    let compile_status = gl.get_shader_parameter_bool(
        shader, gl.COMPILE_STATUS
    );
    if not compile_status then (
        let log = gl.get_shader_info_log(shader);
        panic("Shader compilation failed: " + log);
    );
    shader
);

const AttributeInfo = newtype {
    .raw :: gl.ActiveInfo,
    .index :: Int32,
};

const UniformInfo = newtype {
    .raw :: gl.ActiveInfo,
    .location :: gl.WebGLUniformLocation,
    .index :: Int32,
};

const Program = newtype {
    .ctx :: gl.ContextT,
    .handle :: gl.Program,
    .attributes :: OrdMap.t[String, AttributeInfo],
    .uniforms :: OrdMap.t[String, UniformInfo],
};

impl Program as module = (
    module:
    
    const init = (
        vertex_shader :: gl.Shader,
        fragment_shader :: gl.Shader,
    ) -> Program => (
        let ctx = (@current gl.Context);
        let program = gl.create_program()
            |> Option.unwrap;
        gl.attach_shader(program, vertex_shader);
        gl.attach_shader(program, fragment_shader);
        gl.link_program(program);
        let link_status = gl.get_program_parameter_bool(program, gl.LINK_STATUS);
        if not link_status then (
            let log = gl.get_program_info_log(program);
            panic("Program link failed: " + log);
        );
        let active_attributes = gl.get_program_parameter_int(program, gl.ACTIVE_ATTRIBUTES);
        let mut attributes = OrdMap.new();
        for index in 0..active_attributes do (
            let active_info = gl.get_active_attrib(program, index);
            if active_info.size != 1 then (
                dbg.print(active_info);
                panic("active_info.size != 1");
            );
            let attribute_info = {
                .raw = active_info,
                .index,
            };
            OrdMap.add(&mut attributes, attribute_info.raw.name, attribute_info);
        );
        let active_uniforms = gl.get_program_parameter_int(program, gl.ACTIVE_UNIFORMS);
        let mut uniforms = OrdMap.new();
        for index in 0..active_uniforms do (
            let active_info = gl.get_active_uniform(program, index);
            if active_info.size != 1 then (
                dbg.print(active_info);
                panic("active_info.size != 1");
            );
            let location = gl.get_uniform_location(program, active_info.name)
                |> Option.unwrap;
            let uniform_info = {
                .raw = active_info,
                .location,
                .index,
            };
            OrdMap.add(&mut uniforms, uniform_info.raw.name, uniform_info);
        );
        {
            .ctx,
            .handle = program,
            .attributes,
            .uniforms,
        }
    );
    
    const @"use" = (program :: Program) => (
        gl.use_program(program.handle);
    );
);

const Texture = newtype {
    .size :: Vec2,
    .handle :: gl.WebGLTexture,
};

const Filter = newtype (
    | :Nearest
    | :Linear
);

const Wrap = newtype (
    | :Repeat
    | :ClampToEdge
);

impl Wrap as module = (
    module:
    
    const to_gl = (wrap :: Wrap) -> gl.GLenum => (
        match wrap with (
            | :Repeat => gl.REPEAT
            | :ClampToEdge => gl.CLAMP_TO_EDGE
        )
    );
);

impl Texture as module = (
    module:
    
    const init = (
        image :: web.HtmlImageElement,
        filter :: Filter,
    ) -> Texture => (
        let handle = gl.create_texture();
        gl.bind_texture(gl.TEXTURE_2D, handle);
        gl.pixel_store_bool(gl.UNPACK_FLIP_Y_WEBGL, true);
        gl.pixel_store_bool(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, true);
        gl.tex_parameter_i(
            gl.TEXTURE_2D,
            gl.TEXTURE_MIN_FILTER,
            gl.LINEAR,
        );
        match filter with (
            | :Linear => ()
            | :Nearest => (
                gl.tex_parameter_i(
                    gl.TEXTURE_2D,
                    gl.TEXTURE_MAG_FILTER,
                    gl.NEAREST
                );
            )
        );
        gl.tex_image_2d(
            gl.TEXTURE_2D,
            0,
            gl.RGBA,
            gl.RGBA,
            gl.UNSIGNED_BYTE,
            image |> js.into_any
        );
        # gl.generate_mipmap(gl.TEXTURE_2D);
        gl.tex_parameter_i(
            gl.TEXTURE_2D,
            gl.TEXTURE_WRAP_S,
            gl.CLAMP_TO_EDGE,
        );
        gl.tex_parameter_i(
            gl.TEXTURE_2D,
            gl.TEXTURE_WRAP_T,
            gl.CLAMP_TO_EDGE,
        );
        {
            .size = { image.naturalWidth, image.naturalHeight },
            .handle,
        }
    );
    
    const set_wrap_separate = (
        texture :: &mut Texture,
        s :: Wrap,
        t :: Wrap,
    ) -> () => (
        gl.bind_texture(gl.TEXTURE_2D, texture^.handle);
        gl.tex_parameter_i(
            gl.TEXTURE_2D,
            gl.TEXTURE_WRAP_S,
            s |> Wrap.to_gl,
        );
        gl.tex_parameter_i(
            gl.TEXTURE_2D,
            gl.TEXTURE_WRAP_T,
            t |> Wrap.to_gl,
        );
    );
);

const VertexAttributeType = newtype {
    .size :: gl.GLint,
    .@"type" :: gl.GLenum,
    .type_size :: Int32,
};

const VertexAttribute = [Self] newtype {
    .@"type" :: VertexAttributeType,
    .construct_data :: &ArrayList.t[Self] -> js.Any,
};

impl Vec2 as VertexAttribute = {
    .@"type" = {
        .size = 2,
        .@"type" = gl.FLOAT,
        .type_size = 4,
    },
    .construct_data = data => (
        let list = js.List.new();
        for &{ x, y } in ArrayList.iter(data) do (
            list |> js.List.push(x);
            list |> js.List.push(y);
        );
        js.new_float32_array(list)
    ),
};

impl Vec3 as VertexAttribute = {
    .@"type" = {
        .size = 3,
        .@"type" = gl.FLOAT,
        .type_size = 4,
    },
    .construct_data = data => (
        let list = js.List.new();
        for &{ x, y, z } in ArrayList.iter(data) do (
            list |> js.List.push(x);
            list |> js.List.push(y);
            list |> js.List.push(z);
        );
        js.new_float32_array(list)
    ),
};

impl Vec4 as VertexAttribute = {
    .@"type" = {
        .size = 4,
        .@"type" = gl.FLOAT,
        .type_size = 4,
    },
    .construct_data = data => (
        let list = js.List.new();
        for &{ x, y, z, w } in ArrayList.iter(data) do (
            list |> js.List.push(x);
            list |> js.List.push(y);
            list |> js.List.push(z);
            list |> js.List.push(w);
        );
        js.new_float32_array(list)
    ),
};

const DrawState = newtype {
    .active_texture_index :: Int32,
};

impl DrawState as module = (
    module:
    
    const init = () -> DrawState => (
        let ctx = (@current gl.Context);
        
        gl.enable(gl.BLEND);
        gl.blend_func_separate(
            gl.SRC_ALPHA,
            gl.ONE_MINUS_SRC_ALPHA,
            gl.ONE_MINUS_DST_ALPHA,
            gl.ONE,
        );
        
        { .active_texture_index = 0 }
    );
);

const Uniform = [Self] newtype {
    .set :: (gl.WebGLUniformLocation, Self, &mut DrawState) -> (),
};

impl Float32 as Uniform = {
    .set = (location, x, state) => (
        let ctx = (@current gl.Context);
        let list = js.List.new();
        @js_call ctx."uniform1f"(location, x);
    ),
};

impl Vec2 as Uniform = {
    .set = (location, value, state) => (
        let ctx = (@current gl.Context);
        let list = js.List.new();
        let { x, y } = value;
        @js_call ctx."uniform2f"(location, x, y);
    ),
};

impl Vec3 as Uniform = {
    .set = (location, value, state) => (
        let ctx = (@current gl.Context);
        let list = js.List.new();
        let { x, y, z } = value;
        @js_call ctx."uniform3f"(location, x, y, z);
    ),
};

impl Vec4 as Uniform = {
    .set = (location, value, state) => (
        let ctx = (@current gl.Context);
        let list = js.List.new();
        let { x, y, z, w } = value;
        @js_call ctx."uniform4f"(location, x, y, z, w);
    ),
};

impl Mat3 as Uniform = {
    .set = (location, value, state) => (
        let ctx = (@current gl.Context);
        let list = js.List.new();
        let { a, b, c } = value;
        let add = (f) => (
            list |> js.List.push(f(a));
            list |> js.List.push(f(b));
            list |> js.List.push(f(c));
        );
        add(row => row.0);
        add(row => row.1);
        add(row => row.2);
        let data = js.new_float32_array(list);
        @js_call ctx."uniformMatrix3fv"(location, false, data);
    ),
};

impl Texture as Uniform = {
    .set = (location, texture, state) => (
        let ctx = (@current gl.Context);
        @js_call ctx."activeTexture"(gl.TEXTURE0 + state^.active_texture_index);
        gl.bind_texture(gl.TEXTURE_2D, texture.handle);
        @js_call ctx."uniform1i"(location, state^.active_texture_index);
        state^.active_texture_index += 1;
    ),
};

const set_uniform = [T] (
    program :: Program,
    name :: String,
    value :: T,
    state :: &mut DrawState,
) -> () => with_return (
    let ctx = program.ctx;
    let uniform_info = match &program.uniforms |> OrdMap.get(name) with (
        | :Some (info) => info
        | :None => return
    );
    (T as Uniform).set(uniform_info^.location, value, state);
);

const Vertex = [Self] newtype {
    .init_fields :: (&ArrayList.t[Self], (String, VertexBuffer.Field) -> ()) -> (),
};

const Vertex_derive = (ty :: Type) -> std.Ast => @cfg (
    | target.name == "interpreter" => match std.reflection.type_info(ty) with (
        | :Tuple { .unnamed, .named } => (
            match unnamed with (
                | :Nil => ()
                | :Cons _ => panic("Expected zero unnamed fields")
            );
            const f = `(f);
            const data = `(data);
            let mut init_fields = `();
            for &{ name, field_ty } in std.collections.SList.iter(&named) do (
                let name_ident = std.Ast.ident(name);
                init_fields = `(
                    $init_fields;
                    $f(name, VertexBuffer.init_field($data, v => v^.$name_ident));
                );
            );
            `(
                impl ty as Vertex = {
                    .init_fields = ($data, $f) => (
                        $init_fields
                    ),
                };
            )
        )
        | _ => panic("Can't derive vertex")
    )
    | true => panic("Only usable at comptime")
);

const VertexBuffer = (
    module:
    
    const Field = newtype {
        .buffer :: gl.Buffer,
        .stride :: Int32,
        .offset :: Int32,
        .@"type" :: VertexAttributeType,
    };
    
    const t = [V] newtype {
        .fields :: OrdMap.t[String, Field],
    };
    
    const init = [V] (data :: &ArrayList.t[V]) -> t[V] => (
        let mut fields = OrdMap.new();
        (V as Vertex).init_fields(
            data,
            (name, field) => (
                OrdMap.add(&mut fields, name, field);
            )
        );
        { .fields }
    );
    
    const init_field = [V, T] (
        data :: &ArrayList.t[V],
        get :: &V -> T,
    ) -> Field => (
        let mut field_data = ArrayList.new();
        for vertex in ArrayList.iter(data) do (
            let field = get(vertex);
            &mut field_data |> ArrayList.push_back(field);
        );
        let field_data = (T as VertexAttribute).construct_data(&field_data);
        
        let buffer = gl.create_buffer();
        gl.bind_buffer(gl.ARRAY_BUFFER, buffer);
        gl.buffer_data(gl.ARRAY_BUFFER, field_data, gl.STATIC_DRAW);
        
        let offset = 0;
        let @"type" = (T as VertexAttribute).@"type";
        let stride = @"type".size * @"type".type_size;
        {
            .buffer,
            .stride,
            .offset,
            .@"type",
        }
    );
);

const set_vertex_data_source = [V] (
    program :: Program,
    buffer :: VertexBuffer.t[V],
) -> () => (
    let ctx = program.ctx;
    for &{ .key = name, .value = field } in &buffer.fields |> OrdMap.iter do (
        let attribute_info = match &program.attributes |> OrdMap.get(name) with (
            | :Some (info) => info
            | :None => continue
        );
        gl.bind_buffer(gl.ARRAY_BUFFER, field.buffer);
        gl.vertex_attrib_pointer(
            attribute_info^.index,
            field.@"type".size,
            field.@"type".@"type",
            false,
            field.stride,
            field.offset,
        );
        gl.enable_vertex_attrib_array(attribute_info^.index);
    );
);
