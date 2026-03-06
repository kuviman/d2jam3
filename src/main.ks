use std.collections.OrdMap;
use (import "lib/_lib.ks").*;

# geng.init :: () with (Allocator, Async) -> () with (geng.Context, gl.Context);
# geng.init :: [C] () -> () with C -> C | geng.Ctx | gl.Ctx
# with ...geng.init();
let { .geng = geng_ctx, .gl = gl_ctx } = geng.init();

with geng.Context = geng_ctx;
with gl.Context = gl_ctx;

with geng.input.Context = geng.input.init(geng_ctx.canvas);
with geng.audio.Context = geng.audio.init();

let assets = (
    module:
    
    const load_texture = path => geng.load_texture(
        "assets/textures/" + path,
        :Nearest,
    );
    
    let textures = {
    };
);

include "./player.ks";

const State = newtype {
    .player :: Player,
    .camera :: geng.Camera,
};

impl State as module = (
    module:
    
    const new = () -> State => {
        .player = Player.new(),
        .camera = {
            .pos = { 0, 0 },
            .fov = 10,
        }
    };
    
    const update = (
        state :: &mut State,
        dt :: Float64,
    ) => (
        Player.update(&mut state^.player, dt);
    );
    
    const draw = (state :: &mut State) => (
        let framebuffer_size = {
            geng_ctx.canvas_size.width,
            geng_ctx.canvas_size.height,
        };
        with geng.CameraCtx = geng.CameraUniforms.init(
            state^.camera,
            .framebuffer_size,
        );
        
        ugli.clear({ 0.5, 0.5, 0.5, 1.0 });
        Player.draw(&state^.player);
    );
    
    const handle_event = (
        state :: &mut State,
        event :: geng.input.Event,
    ) => (
        # TODO
    );
);

let mut state = State.new();
let mut t = time.now();
loop (
    let dt = (
        let new_t = time.now();
        let dt = new_t - t;
        t = new_t;
        dt
    );
    for event in geng.input.iter_events() do (
        State.handle_event(&mut state, event);
    );
    State.update(&mut state, dt);
    State.draw(&mut state);
    
    geng.await_next_frame();
);
