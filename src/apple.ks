const Apple = newtype {
    .pos :: Vec2,
    .vel :: Vec2,
    .rot :: Float32,
    .w :: Float32,
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
        const W = 4;
        {
            .pos,
            .vel = {
                std.random.gen_range(.min = -V, .max = +V),
                2 + std.random.gen_range(.min = 0, .max = 8),
            },
            .rot = std.random.gen_range(.min = 0, .max = 2 * Float32.PI),
            .w = std.random.gen_range(.min = -W, .max = +W),
            .catched = false,
        }
    );
    
    const update = (apple :: &mut Apple, dt :: Float32) => (
        let vy = &mut apple^.vel.1;
        vy^ = max(vy^ - GRAVITY * dt, -MAX_SPEED);
        apple^.pos = Vec2.add(apple^.pos, Vec2.mul(apple^.vel, dt));
        apple^.rot += apple^.w * dt;
    );
    
    const draw = (apple :: &Apple) => (
        geng.draw_quad_ext(
            .model_matrix = Mat3.translate(apple^.pos)
                |> Mat3.mul_mat(Mat3.rotate(apple^.rot))
                |> Mat3.mul_mat(Mat3.scale({ RADIUS, RADIUS })),
            .texture = assets.textures.apple,
            .uv = Rect.UNIT,
        );
    );
);