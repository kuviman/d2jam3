const TreeApple = newtype {
    .pos :: Vec2,
};

const Tree = newtype {
    .pos :: Vec2,
    .growth :: Float32,
    .apple_growth :: Float32,

    .apples :: js.List.t[TreeApple],
    
    .animation :: {
        .phase :: Float32,
    },
};

let sheet = Sheet.load("assets/textures/tree/sheet.png", .total_layers = 5);

impl Tree as module = (
    module:
    
    const GROWTH_TIME = 2;
    const APPLE_GROWTH_TIME = 3;
    const LEAF_ANIMATION_SPEED = 2;
    const LEAF_ANIMATION_AMP = degree_to_rad(1);
    
    const new = (pos) -> Tree => {
        .pos = { pos, 0 },
        .growth = 0,
        .apple_growth = 0,
        .animation = {
            .phase = 0,
        },
        .apples = (
            let list = js.List.new();
            for _ in 0..std.random.gen_range(.min = 1, .max = 5) do (
                let a = std.random.gen_range(.min = 0, .max = 2 * Float32.PI);
                let r = Float32.pow(std.random.gen_range(.min = 0, .max = 1), 1/2);
                let apple = {
                    .pos = Vec2.add({ pos, 2.3 }, Vec2.rotate({ r, 0 }, a)),
                };
                js.List.push(list, apple);
            );
            list
        ),
    };
    
    const update = (tree :: &mut Tree, dt :: Float64) => (
        tree^.growth += dt / GROWTH_TIME;
        if tree^.growth > 1 then (
            tree^.growth = 1;
            tree^.apple_growth += dt / APPLE_GROWTH_TIME;
        );
        add_to_angle(&mut tree^.animation.phase, dt * LEAF_ANIMATION_SPEED);
    );

    const MAX_SCALE = 2;
    const scale = (tree :: &Tree) -> Float32 => (
        (1 - sqr(1 - tree^.growth)) * MAX_SCALE
    );
    
    const draw = (tree :: &Tree) => (
        const layers = {
            .trunk = { .idx = 4, .origin = { 32, 64 } },
            .leaves1 = { .idx = 3, .origin = { 15, 32 } },
            .leaves2 = { .idx = 2, .origin = { 47, 34 } },
            .leaves3 = { .idx = 1, .origin = { 41, 13 } },
        };
        let scale = scale(tree);
        let scale_leaves = sqr(scale / MAX_SCALE) * MAX_SCALE;
        let pos = Vec2.add(tree^.pos, { 0, scale + (1 - tree^.growth) * -0.3 });
        let draw_layer = (sheet, .layer, ...args) => (
            let origin = (
                # recalculate from aseprite coords to unit quad coords
                let { x, y } = Vec2.vdiv(layer.origin, sheet.image_size);
                { x * 2 - 1, 1 - y * 2 }
            );
            Sheet.draw_layer(
                sheet,
                .layer,
                .pos = Vec2.add(pos, Vec2.mul(origin, scale)),
                .flip = false,
                ...args
            );
        );
        draw_layer(
            sheet,
            .layer = layers.trunk,
            .rotation = 0,
            .scale,
        );
        let rot = x => (
            Float32.sin(tree^.animation.phase + x) * LEAF_ANIMATION_AMP
        );
        draw_layer(
            sheet,
            .layer = layers.leaves1,
            .rotation = rot(0),
            .scale = scale_leaves,
        );
        draw_layer(
            sheet,
            .layer = layers.leaves2,
            .rotation = rot(1),
            .scale = scale_leaves,
        );
        draw_layer(
            sheet,
            .layer = layers.leaves3,
            .rotation = rot(2),
            .scale = scale_leaves,
        );
        let apple_growth = Float32.pow(tree^.apple_growth, 1/2);
        for apple in js.List.iter(tree^.apples) do (
            const radius :: Float32 = 1/4;
            let r = radius * apple_growth;
            geng.draw_quad_ext(
                .model_matrix = Mat3.translate(apple.pos)
                    |> Mat3.mul_mat(Mat3.scale({ r, r })),
                .texture = assets.textures.apple,
                .uv = Rect.UNIT,
                .color = { 1, 1, 1, 1 },
            );
        );
    )
);
