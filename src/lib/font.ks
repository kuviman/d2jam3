use (import "./common.ks").*;
const gl = import "./gl/gl.ks";
const ugli = import "./ugli.ks";
const geng = import "./geng/_lib.ks";
use std.collections.OrdMap;

module:

const TilePos = Vec2;

const RangeConfig = newtype {
    .start :: Char,
    .end :: Char,
    .at :: TilePos,
};

const Config = newtype {
    .tile_size :: Vec2,
    .kerning :: Float32,
    .space_size :: Float32,
    .chars :: js.Obj.t[TilePos],
    .ranges :: js.List.t[RangeConfig],
};

const UvRect = newtype {
    .pos :: Vec2,
    .size :: Vec2,
};

const Font = newtype {
    .config :: Config,
    .unit_space_size :: Float32,
    .texture :: ugli.Texture,
    .chars :: OrdMap.t[Char, UvRect],
    .program :: ugli.Program,
};

const single_char = (s :: String) -> Char => (
    if s |> String.length != 1 then (
        panic("c.length != 1");
    );
    s |> String.at(0)
);

impl Font as module = (
    module:
    
    const load = (path :: String) -> Font => (
        let config :: Config = fetch_string(path + "/config.json") |> js.json_parse;
        let texture = geng.load_texture(path + "/texture.png", :Nearest);
        let mut chars = OrdMap.new();
        let tile_size_uv = Vec2.vdiv(config.tile_size, texture.size);
        let uv_rect = (tile_pos :: Vec2) -> UvRect => {
            .pos = Vec2.vdiv(Vec2.vmul(tile_pos, config.tile_size), texture.size),
            .size = tile_size_uv,
        };
        let texture_size_tiles = Vec2.vdiv(texture.size, config.tile_size);
        let add_c = (c :: Char, tile_pos :: Vec2) => (
            let tile_pos :: Vec2 = {
                tile_pos.0,
                texture_size_tiles.1 - 1 - tile_pos.1,
            };
            # dbg.print(.c, .tile_pos, .uv_rect = uv_rect(tile_pos));
            &mut chars
                |> OrdMap.add(c, uv_rect(tile_pos));
        );
        for { c, tile_pos } in config.chars |> js.Obj.iter do (
            add_c(c |> single_char, tile_pos);
        );
        for range in config.ranges |> js.List.iter do (
            let mut tile_pos = range.at;
            for c in Char.code(range.start)..Char.code(range.end) + 1 do (
                add_c(Char.from_code(c), tile_pos);
                tile_pos.0 += 1;
            );
        );
        let program = geng.load_shader("assets/shaders/font");
        {
            .unit_space_size = config.space_size / config.tile_size.1,
            .config,
            .texture,
            .chars,
            .program,
        }
    );
    
    const measure = (font :: &Font, text :: String) -> Float32 => (
        let size :: Float32 = 1;
        let tile_size = font^.config.tile_size;
        let single_char_size = Vec2.mul({ tile_size.0 / tile_size.1, 1 }, size);
        let mut result = 0;
        for c in text |> String.iter do (
            if c == ' ' then (
                result += font^.unit_space_size * size;
                continue;
            );
            result += single_char_size.0;
        );
        result
    );
    
    const draw = (
        font :: &Font,
        text :: String,
        .pos :: Vec2,
        .size :: Float32,
        .color :: Vec4,
        .align :: Float32,
    ) => (
        let ctx = (@current geng.Context);
        let camera = (@current geng.CameraCtx);
        let program = font^.program;
        program |> ugli.Program.@"use";
        
        let mut draw_state = ugli.DrawState.init();
        let draw_state = &mut draw_state;
        
        program |> ugli.set_vertex_data_source(ctx.quad.buffer);
        
        program |> ugli.set_uniform("u_view_matrix", camera.view_matrix, draw_state);
        program |> ugli.set_uniform("u_projection_matrix", camera.projection_matrix, draw_state);
        program |> ugli.set_uniform("u_texture", font^.texture, draw_state);
        program |> ugli.set_uniform("u_color", color, draw_state);
        
        let tile_size = font^.config.tile_size;
        let single_char_size = Vec2.mul({ tile_size.0 / tile_size.1, 1 }, size);
        program |> ugli.set_uniform("u_size", single_char_size, draw_state);
        let mut pos :: Vec2 = { pos.0 - measure(font, text) * align * size, pos.1 };
        for c in text |> String.iter do (
            if c == ' ' then (
                pos.0 += font^.unit_space_size * size;
                continue;
            );
            match &font^.chars |> OrdMap.get(c) with (
                | :None => panic("Char " + to_string(c) + " is not in font")
                | :Some (&uv) => (
                    program |> ugli.set_uniform("u_uv_rect_pos", uv.pos, draw_state);
                    program |> ugli.set_uniform("u_uv_rect_size", uv.size, draw_state);
                )
            );
            program |> ugli.set_uniform("u_pos", pos, draw_state);
            gl.draw_arrays(gl.TRIANGLE_FAN, 0, 4);
            
            pos.0 += single_char_size.0;
        );
    );
);
