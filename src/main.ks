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
        .house = load_texture("house.png"),
        .score_particle = load_texture("score.png"),
        .explosion = load_texture("explosion.png"),
    };
);


const PLAYABLE_AREA = 6;
const PlantType = newtype (
    | :AppleTree
);

include "./apple.ks";
include "./fps.ks";
include "./sheet.ks";
include "./player.ks";
include "./tree.ks";
include "./truck.ks";
include "./seed.ks";

const Particle = newtype {
    .pos :: Vec2,
    .vel :: Vec2,
    .rot :: Float32,
    .scale :: Float32,
    .w :: Float32,
    .t :: Float32,
    .texture :: ugli.Texture,
};

impl Particle as module = (
    module:

    const update = (self :: &mut Particle, dt :: Float32) => (
        self^.pos = Vec2.add(self^.pos, Vec2.mul(self^.vel, dt));
        self^.t += dt;
    );

    const draw = (self :: &Particle) => (
        let scale = self^.scale;
        geng.draw_quad_ext(
            .model_matrix = Mat3.translate(self^.pos)
                |> Mat3.mul_mat(Mat3.rotate(self^.rot))
                |> Mat3.mul_mat(Mat3.scale({ scale, scale })),
            .texture = self^.texture,
            .uv = Rect.UNIT,
            .color = { 1, 1, 1, 1 - self^.t },
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
    .particles :: js.List.t[Particle],
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
        .particles = js.List.new(),
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
                js.List.push(state^.particles, {
                    .pos = apple^.pos,
                    .vel = { 0, 1 },
                    .t = 0,
                    .rot = 0,
                    .w = 0,
                    .scale = 1/4,
                    .texture = assets.textures.score_particle,
                });
            );
        );
        for ref mut tree in state^.trees |> js.List.iter do (
            Tree.update(tree, dt);
            if tree^.apple_growth >= 1 then (
                for apple in js.List.iter(tree^.apples) do (
                    js.List.push(state^.apples, Apple.new(apple.pos));
                );
                for _ in 0..15 do (
                    const V = 1;
                    const W = 5;
                    js.List.push(state^.particles, {
                        .pos = Vec2.add(tree^.pos, {
                            std.random.gen_range(.min = -1, .max = +1),
                            2.2 + std.random.gen_range(.min = -1, .max = +1),
                        }),
                        .vel = {
                            std.random.gen_range(.min = -V, .max = +V),
                            std.random.gen_range(.min = -V, .max = +V),
                        },
                        .t = 0,
                        .rot = std.random.gen_range(.min = 0, .max = 2 * Float32.PI),
                        .w = std.random.gen_range(.min = -W, .max = +W),
                        .scale = 1/2,
                        .texture = assets.textures.explosion,
                    });
                );
            );
        );
        state^.trees = js.List.filter(
            state^.trees,
            tree => tree.apple_growth < 1,
        );
        state^.apples = js.List.filter(
            state^.apples,
            apple => apple.pos.1 > -3 and not apple.catched,
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

        for ref mut p in js.List.iter(state^.particles) do (
            Particle.update(p, dt);
        );
        state^.particles = js.List.filter(
            state^.particles,
            p => p.t < 1,
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
        geng.draw_quad(
            .pos = { -9, 2 },
            .half_size = { 2, 2 },
            .texture = assets.textures.house,
        );

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
                    closest_tree |> Option.map(tree => (
                        Vec2.add(tree.pos, { 0, Tree.scale(&tree) })
                    ))
                ))
                |> Option.unwrap_or ({ 9, 2 })
        );
        for ref apple in state^.apples |> js.List.iter do (
            Apple.draw(apple);
        );

        for ref p in js.List.iter(state^.particles) do (
            Particle.draw(p);
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
