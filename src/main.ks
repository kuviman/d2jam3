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

    let font = font.Font.load("assets/font");
    
    const load_texture = path => geng.load_texture(
        "assets/textures/" + path,
        :Nearest,
    );
    
    let textures = {
        .apple = load_texture("apple.png"),
        .ground = load_texture("ground.png"),
    };
);

include "./fps.ks";
include "./sheet.ks";
include "./player.ks";
include "./tree.ks";

const Apple = newtype {
    .pos :: Vec2,
    .vel :: Vec2,
};

impl Apple as module = (
    module:
    
    const RADIUS = std.op.div[Float32](1, 4);
    const GRAVITY = 8;
    const MAX_SPEED = 8;
    
    const SPAWN_RATE = 1;
    
    const new = () -> Apple => (
        const D = 5;
        let x = std.random.gen_range(.min = -D, .max = +D);
        const V = 5;
        let vx = std.random.gen_range(.min = -V, .max = +V);
        {
            .pos = { x, 1 },
            .vel = { vx, 8 },
        }
    );
    
    const update = (apple :: &mut Apple, dt :: Float32) => (
        let vy = &mut apple^.vel.1;
        vy^ = max(vy^ - GRAVITY * dt, -MAX_SPEED);
        apple^.pos = Vec2.add(apple^.pos, Vec2.mul(apple^.vel, dt));
    );
    
    const draw = (apple :: &Apple) => (
        geng.draw_quad(
            .pos = apple^.pos,
            .half_size = { RADIUS, RADIUS },
            .texture = assets.textures.apple,
        );
    );
);

const State = newtype {
    .player :: Player,
    .camera :: geng.Camera,
    .apples :: js.List.t[Apple],
    .trees :: js.List.t[Tree],
    .next_apple_spawn :: Float32,
};

impl State as module = (
    module:
    
    const new = () -> State => {
        .player = Player.new(),
        .camera = {
            .pos = { 0, 3 },
            .fov = 10,
        },
        .apples = js.List.new(),
        .trees = js.List.new(),
        .next_apple_spawn = 0,
    };
    
    const update = (
        state :: &mut State,
        dt :: Float64,
    ) => (
        Player.update(&mut state^.player, dt);
        for ref mut apple in state^.apples |> js.List.iter do (
            Apple.update(apple, dt);
        );
        for ref mut tree in state^.trees |> js.List.iter do (
            Tree.update(tree, dt);
        );
        state^.apples = js.List.filter(
            state^.apples,
            apple => apple.pos.1 > 0,
        );
        state^.next_apple_spawn -= dt;
        while state^.next_apple_spawn < 0 do (
            state^.next_apple_spawn += 1 / Apple.SPAWN_RATE;
            spawn_apple(state);
        );
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

        for ref tree in state^.trees |> js.List.iter do (
            Tree.draw(tree);
        );

        draw_ground();

        let closest_apple = state^.apples
            |> js.List.iter
            |> min_by_key(apple => Vec2.len2(Vec2.sub(apple.pos, state^.player.pos)));
        Player.draw(
            &state^.player,
            .look_at = closest_apple
                |> Option.map(apple => apple.pos)
                |> Option.unwrap_or({ state^.player.pos.0, -10 })
        );
        for ref apple in state^.apples |> js.List.iter do (
            Apple.draw(apple);
        );
    );

    const draw_ground = () => (
        let texture = assets.textures.ground;
        let half_size = Vec2.mul(texture.size, 1/32);
        let pos = {0, -half_size.1};
        geng.draw_quad(.pos, .half_size, .texture);
    );
    
    const spawn_apple = (state :: &mut State) => (
        js.List.push(state^.apples, Apple.new());
    );
    
    const handle_event = (
        state :: &mut State,
        event :: geng.input.Event,
    ) => (
        if event is :PointerPress _ then (
            js.List.push(state^.trees, Tree.new(state^.player.pos));
        );
    );
);

let mut state = State.new();
let mut t = time.now();
let mut fps_counter = FpsCounter.new();
loop (
    let dt = (
        let new_t = time.now();
        let dt = new_t - t;
        t = new_t;
        min(dt, 0.1)
    );
    for event in geng.input.iter_events() do (
        State.handle_event(&mut state, event);
    );
    State.update(&mut state, dt);
    State.draw(&mut state);

    FpsCounter.frame(&mut fps_counter, dt);
    FpsCounter.draw(&fps_counter);
    
    geng.await_next_frame();
);
