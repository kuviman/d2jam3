const Player = newtype {
    .pos :: Vec2,
    .vel :: Vec2,
    
    .animation :: {
        .leg_phase :: Float32,
    },
};

let sheet = geng.load_texture(
    "assets/textures/player/sheet.png",
    :Nearest,
);

impl Player as module = (
    module:
    
    const ACCEL = 10;
    const SPEED = 6;
    const LEG_PHASE_SPEED = 20;
    
    const new = () -> Player => {
        .pos = { 0, 0 },
        .vel = { 0, 0 },
        .animation = {
            .leg_phase = 0,
        }
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
            let target_vel = dir * SPEED;
            let acc = (target_vel - player^.vel.0) * ACCEL;
            clamp(
                player^.vel.0 + acc * dt,
                .min = -SPEED,
                .max = +SPEED,
            )
        );
        player^.pos = Vec2.add(player^.pos, Vec2.mul(player^.vel, dt));
        
        (
            let x = &mut player^.animation.leg_phase;
            x^ += dt * LEG_PHASE_SPEED;
            while x^ > 2 * Float32.PI do (
                x^ -= 2.0 * Float32.PI;
            );
        );
    );
    
    const draw = (player :: &Player) => (
        const layers = {
            .arm_left = { .idx = 0, .origin = { 11, 13 } },
            .arm_right = { .idx = 1, .origin = { 20, 13 } },
            .head = { .idx = 2, .origin = { 14, 10 } },
            .body = { .idx = 3, .origin = { 14, 16 } },
            .leg_left = { .idx = 4, .origin = { 11, 21 } },
            .leg_right = { .idx = 5, .origin = { 17, 21 } },
        };
        const total_layers = 7;
        let pixel_size = Vec2.vdiv({ 1, 1 }, sheet.size);
        let image_size = Vec2.sub(
            Vec2.vdiv(sheet.size, { 1, total_layers }),
            { 2, 2 } # because gaps & border
        );
        let layer_uv_size = Vec2.sub(
            { 1, 1 / total_layers },
            Vec2.mul(pixel_size, 2),
        );
        let pos = player^.pos;
        let draw_layer = (
            .layer,
            .rotation,
        ) => (
            let origin = (
                # recalculate from aseprite coords to unit quad coords
                let { x, y } = Vec2.vdiv(layer.origin, image_size);
                { x * 2 - 1, 1 - y * 2 }
            );
            geng.draw_quad_ext(
                .pos = Vec2.sub(
                    Vec2.add(pos, origin),
                    Vec2.rotate(origin, rotation),
                ),
                .half_size = { 1, 1 },
                .texture = sheet,
                .uv = {
                    .bottom_left = Vec2.add(
                        { 0, layer.idx / total_layers },
                        pixel_size,
                    ),
                    .size = layer_uv_size,
                },
                .rotation,
            );
        );
        (
            # LEGS
            let phase = player^.animation.leg_phase;
            let k = Vec2.len(player^.vel) / SPEED;
            const leg_amp = degree_to_rad(30);
            let rot = Float32.sin(phase) * leg_amp * k;
            draw_layer(
                .layer = layers.leg_right,
                .rotation = -rot,
            );
            draw_layer(
                .layer = layers.leg_left,
                .rotation = rot,
            );
        );
        draw_layer(
            .layer = layers.arm_right,
            .rotation = 0,
        );
        draw_layer(
            .layer = layers.body,
            .rotation = 0,
        );
        draw_layer(
            .layer = layers.head,
            .rotation = degree_to_rad(30),
        );
        draw_layer(
            .layer = layers.arm_left,
            .rotation = 0,
        );
    )
);
