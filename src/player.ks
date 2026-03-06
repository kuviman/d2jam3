const Player = newtype {
    .pos :: Vec2,
    .vel :: Vec2,
    
    .animation :: {
        .leg_phase :: Float32,
        .wheel_rot :: Float32,
    },
};

const Sheet = newtype {
    .total_layers :: Float32,
    .texture :: ugli.Texture,
    .image_size :: Vec2,
    .pixel_size :: Vec2,
    .layer_uv_size :: Vec2,
};

impl Sheet as module = (
    module:
    
    const load = (path :: String, .total_layers) -> Sheet => (
        let texture = geng.load_texture(path, :Nearest);
        let pixel_size = Vec2.vdiv({ 1, 1 }, texture.size);
        let image_size = Vec2.sub(
            Vec2.vdiv(texture.size, { 1, total_layers }),
            { 2, 2 } # because gaps & border
        );
        let layer_uv_size = Vec2.sub(
            { 1, 1 / total_layers },
            Vec2.mul(pixel_size, 2),
        );
        {
            .texture,
            .pixel_size,
            .image_size,
            .layer_uv_size,
            .total_layers,
        }
    );
    
    const draw_layer = (
        sheet :: Sheet,
        .layer,
        .pos,
        .rotation,
        .flip,
    ) => (
        let origin = (
            # recalculate from aseprite coords to unit quad coords
            let { x, y } = Vec2.vdiv(layer.origin, sheet.image_size);
            { x * 2 - 1, 1 - y * 2 }
        );
        geng.draw_quad_ext(
            .model_matrix = Mat3.translate(Vec2.add(pos, origin))
                |> Mat3.mul_mat(Mat3.rotate(rotation))
                |> Mat3.mul_mat(
                    Mat3.scale({ if flip then -1 else 1, 1 })
                ) |> Mat3.mul_mat(Mat3.translate(Vec2.neg(origin))),
            .texture = sheet.texture,
            .uv = {
                .bottom_left = Vec2.add(
                    { 0, layer.idx / sheet.total_layers },
                    sheet.pixel_size,
                ),
                .size = sheet.layer_uv_size,
            },
        );
    );
);

let sheets = {
    .player = Sheet.load(
        "assets/textures/player/sheet.png",
        .total_layers = 7,
    ),
    .cart = Sheet.load(
        "assets/textures/cart/sheet.png",
        .total_layers = 2,
    ),
};

impl Player as module = (
    module:
    
    const ACCEL = 10;
    const SPEED = 6;
    const LEG_PHASE_SPEED :: Float32 = 20;
    const WHEEL_ROT_SPEED :: Float32 = std.op.neg[Float32](2);
    
    const new = () -> Player => {
        .pos = { 0, 0 },
        .vel = { 0, 0 },
        .animation = {
            .leg_phase = 0,
            .wheel_rot = 0,
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
        
        add_to_angle(
            &mut player^.animation.leg_phase,
            LEG_PHASE_SPEED * dt,
        );
        add_to_angle(
            &mut player^.animation.wheel_rot,
            WHEEL_ROT_SPEED * dt * player^.vel.0,
        );
    );
    
    const draw = (player :: &Player, .look_at :: Vec2) => (
        let movement_k = Vec2.len(player^.vel) / SPEED;
        let movement_signed_k = player^.vel.0 / SPEED * 2;
        let top_offset :: Vec2 = { movement_signed_k * 0.1, 0 };
        let top_pos = Vec2.add(player^.pos, top_offset);
        let shake_angle = (
            Float32.sin(player^.animation.leg_phase * 2)
            * movement_k
            * degree_to_rad(1)
        );
        let arm_shake_angle = -shake_angle * 5;
        
        # Guy
        const layers = {
            .arm_left = { .idx = 0, .origin = { 11, 13 } },
            .arm_right = { .idx = 1, .origin = { 20, 13 } },
            .head = { .idx = 2, .origin = { 14, 10 } },
            .body = { .idx = 3, .origin = { 14, 21 } },
            .leg_left = { .idx = 4, .origin = { 11, 21 } },
            .leg_right = { .idx = 5, .origin = { 17, 21 } },
        };
        let pos = player^.pos;
        let sheet = sheets.player;
        (
            # LEGS
            let phase = player^.animation.leg_phase;
            const leg_amp = degree_to_rad(30);
            let rot = Float32.sin(phase) * leg_amp * movement_k;
            Sheet.draw_layer(
                sheet,
                .layer = layers.leg_right,
                .pos,
                .rotation = -rot,
                .flip = false,
            );
            Sheet.draw_layer(
                sheet,
                .layer = layers.leg_left,
                .pos,
                .rotation = rot,
                .flip = false,
            );
        );
        Sheet.draw_layer(
            sheet,
            .layer = layers.arm_right,
            .pos = top_pos,
            .rotation = degree_to_rad(-60) + arm_shake_angle,
            .flip = false,
        );
        Sheet.draw_layer(
            sheet,
            .layer = layers.body,
            .pos,
            .rotation = degree_to_rad(-10) * movement_signed_k,
            .flip = false,
        );
        
        (
            let flip = look_at.0 < top_pos.0;
            let origin_angle = if flip then Float32.PI else 0;
            Sheet.draw_layer(
                sheet,
                .layer = layers.head,
                .pos = top_pos,
                .rotation = normalize_angle_pi(
                    Vec2.arg(Vec2.sub(look_at, top_pos)) - origin_angle
                )
                / 2,
                .flip,
            );
        );
        
        (
            # Cart
            const layers = {
                .wheel = { .idx = 0, .origin = { 24.5, 27.5 } },
                .body = { .idx = 1, .origin = { 24, 27 } },
            };
            let pos = Vec2.add(player^.pos, { 1, 0 });
            let sheet = sheets.cart;
            Sheet.draw_layer(
                sheet,
                .layer = layers.body,
                .pos,
                .rotation = shake_angle + degree_to_rad(-2) * movement_signed_k,
                .flip = false,
            );
            Sheet.draw_layer(
                sheet,
                .layer = layers.wheel,
                .pos,
                .rotation = player^.animation.wheel_rot,
                .flip = false,
            );
        );
        
        Sheet.draw_layer(
            sheet,
            .layer = layers.arm_left,
            .pos = top_pos,
            .rotation = degree_to_rad(-20) + arm_shake_angle,
            .flip = false,
        );
    )
);
