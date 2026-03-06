const Player = newtype {
    .pos :: Vec2,
    .vel :: Vec2,
};

let sheet = geng.load_texture(
    "assets/textures/player/sheet.png",
    :Nearest,
);

impl Player as module = (
    module:
    
    const new = () -> Player => {
        .pos = { 0, 0 },
        .vel = { 0, 0 },
    };
    
    const update = (player :: &mut Player, dt :: Float64) => (
        player^.vel.0 = (
            let mut dir = 0;
            if geng.input.Key.is_pressed(:ArrowLeft) then (
                dir -= 1;
            );
            if geng.input.Key.is_pressed(:ArrowRight) then (
                dir += 1;
            );
            let speed = 1;
            dir * speed
        );
        player^.pos = Vec2.add(player^.pos, Vec2.mul(player^.vel, dt));
    );
    
    const draw = (player :: &Player) => (
        const layers = {
            .arm_left = 0,
            .arm_right = 1,
            .head = 2,
            .body = 3,
            .leg_left = 4,
            .leg_right = 5,
            .background = 6,
        };
        let total_layers = 7;
        let pixel_size = Vec2.vdiv({ 1, 1 }, sheet.size);
        let layer_uv_size = Vec2.sub(
            { 1, 1 / total_layers },
            Vec2.mul(pixel_size, 2),
        );
        let draw_layer = (.pos, .layer) => (
            geng.draw_quad_subtexture(
                .pos,
                .half_size = { 1, 1 },
                .texture = sheet,
                .uv = {
                    .bottom_left = Vec2.add(
                        { 0, layer / total_layers },
                        pixel_size,
                    ),
                    .size = layer_uv_size,
                },
            );
        );
        draw_layer(.pos = player^.pos, .layer = layers.leg_right);
        draw_layer(.pos = player^.pos, .layer = layers.leg_left);
        draw_layer(.pos = player^.pos, .layer = layers.arm_right);
        draw_layer(.pos = player^.pos, .layer = layers.body);
        draw_layer(.pos = player^.pos, .layer = layers.head);
        draw_layer(.pos = player^.pos, .layer = layers.arm_left);
    )
);
