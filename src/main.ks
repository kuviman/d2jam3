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


const PLAYABLE_AREA = 6;
const PlantType = newtype (
    | :AppleTree
);

include "./fps.ks";
include "./sheet.ks";
include "./player.ks";
include "./tree.ks";
include "./truck.ks";
include "./seed.ks";

const Apple = newtype {
    .pos :: Vec2,
    .vel :: Vec2,
    .catched :: Bool,
};

impl Apple as module = (
    module:
    
    const RADIUS = std.op.div[Float32](1, 4);
    const GRAVITY = 8;
    const MAX_SPEED = 8;
    
    const SPAWN_RATE = 1;
    
    const new = (pos) -> Apple => (
        const V = 2;
        {
            .pos,
            .vel = {
                std.random.gen_range(.min = -V, .max = +V),
                5 + std.random.gen_range(.min = 0, .max = 6),
            },
            .catched = false,
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
    .truck :: Option.t[Truck],
    .seed :: Option.t[Seed],
    .score :: Int32,
};

impl State as module = (
    module:
    
    const new = () -> State => {
        .player = Player.new(),
        .camera = {
            .pos = { 0, 3 },
            .fov = :Horizontal 20,
        },
        .apples = js.List.new(),
        .trees = js.List.new(),
        .truck = :None,
        .seed = :None,
        .score = 0,
    };
    
    const update = (
        state :: &mut State,
        dt :: Float64,
    ) => (
        Player.update(&mut state^.player, dt);
        let cart_pos = Vec2.add(state^.player.pos, { 1, 0.5 });
        for ref mut apple in state^.apples |> js.List.iter do (
            Apple.update(apple, dt);
            if Vec2.len(Vec2.sub(apple^.pos, cart_pos)) < 0.7 then (
                apple^.catched = true;
                state^.score += 1;
            );
        );
        for ref mut tree in state^.trees |> js.List.iter do (
            Tree.update(tree, dt);
            if tree^.apple_growth >= 1 then (
                for _ in 0..3 do (
                    js.List.push(state^.apples, Apple.new(
                        Vec2.add(tree^.pos, { 0, 2 })
                    ));
                );
            );
        );
        state^.trees = js.List.filter(
            state^.trees,
            tree => tree.apple_growth < 1,
        );
        state^.apples = js.List.filter(
            state^.apples,
            apple => apple.pos.1 > 0 and not apple.catched,
        );

        if state^.truck is :Some ref mut truck then (
            Truck.update(truck, dt);
            if truck^.state is :Standing then (
                if state^.player.pos.0 > 8 then (
                    truck^.state = :Leaving;
                    state^.seed = :Some Seed.new(truck^.plant_type);
                );
            );
            if truck^.pos > 20 then (
                state^.truck = :None;
            );
        ) else if state^.player.pos.0 < 8 then (
            state^.truck = :Some Truck.new();
        );

        if state^.seed is :Some ref mut seed then (
            Seed.update(seed, dt);
            if seed^.t > 1 then (
                match seed^.plant_type with (
                    | :AppleTree => (
                        js.List.push(state^.trees, Tree.new(seed^.target));
                    )
                );
                state^.seed = :None;
            );
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
        ugli.clear({ 0.8, 0.8, 1, 1 });

        for ref tree in state^.trees |> js.List.iter do (
            Tree.draw(tree);
        );

        draw_ground();
        if state^.truck is :Some ref truck then (
            Truck.draw(truck);
        );
        if state^.seed is :Some ref seed then (
            Seed.draw(seed);
        );

        Player.draw(
            &state^.player,
            .look_at = 
                state^.seed |> Option.map(seed => Seed.pos(&seed))
                |> or_else(() => (
                    let closest_apple = state^.apples
                        |> js.List.iter
                        |> min_by_key(apple => (
                            Vec2.len2(Vec2.sub(apple.pos, state^.player.pos))
                        ));
                    closest_apple |> Option.map(apple => apple.pos)
                ))
                |> or_else(() => (
                    let closest_tree = state^.trees
                        |> js.List.iter
                        |> min_by_key(tree => (
                            Vec2.len2(Vec2.sub(tree.pos, state^.player.pos))
                        ));
                    closest_tree |> Option.map(tree => tree.pos)
                ))
                |> Option.unwrap_or ({ state^.player.pos.0 + 1, -10 })
        );
        for ref apple in state^.apples |> js.List.iter do (
            Apple.draw(apple);
        );

        draw_score(state);
    );

    const draw_score = (state :: &mut State) => (
        with geng.CameraCtx = geng.CameraUniforms.init(
            { .pos = { 0, 0 }, .fov = :Vertical 30 },
            .framebuffer_size = (@current geng.CameraCtx).framebuffer_size,
        );
        let text = "SCORE: " + to_string(state^.score);
        font.Font.draw(
            &assets.font,
            text,
            .pos = { 0, 12 },
            .size = 2,
            .color = { 0, 0, 0, 1 },
            .align = 0.5,
        );
    );

    const draw_ground = () => (
        let texture = assets.textures.ground;
        let half_size = Vec2.mul(texture.size, 1/32);
        let pos = {0, -half_size.1};
        geng.draw_quad(.pos, .half_size, .texture);
    );
    
    const handle_event = (
        state :: &mut State,
        event :: geng.input.Event,
    ) => (
        if event is :PointerPress _ then (
            # state^.truck = :Some Truck.new();
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
