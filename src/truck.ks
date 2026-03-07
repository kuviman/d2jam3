const Truck = newtype {
    .pos :: Float32,
    .vel :: Float32,
    .target_vel :: Float32,
    .state :: (:Arriving | :Standing | :Leaving),
    .animation :: {
        .wheel_rot :: Float32,
    },
};

let sheet = Sheet.load(
    "assets/textures/truck/sheet.png",
    .total_layers = 4,
);

impl Truck as module = (
    module:
    
    const SPEED = 10;
    const ACC = 10;
    
    const new = () -> Truck => {
        .pos = 15,
        .vel = -SPEED,
        .target_vel = 0,
        .state = :Arriving,
        .animation = {
            .wheel_rot = 0,
        },
    };
    
    const update = (truck :: &mut Truck, dt :: Float64) => (
        let target_dir = match truck^.state with (
            | :Arriving => (
                if truck^.pos < 15 then (
                    truck^.state = :Standing;
                );
                -1
            )
            | :Standing => 0
            | :Leaving => 1
        );
        let target_vel = target_dir * SPEED;
        truck^.target_vel = target_vel;
        truck^.vel += clamp_abs(target_vel - truck^.vel, .max_abs = ACC * dt);
        truck^.pos += truck^.vel * dt;
        add_to_angle(
            &mut truck^.animation.wheel_rot,
            -truck^.vel * dt / 2,
        );
    );
    
    const draw = (truck :: &Truck) => (
        const layers = {
            .wheel1 = { .idx = 2, .origin = { 32, 56 } },
            .wheel2 = { .idx = 1, .origin = { 52, 56 } },
            .wheel3 = { .idx = 0, .origin = { 112, 56 } },
            .body = { .idx = 3, .origin = { 64, 55 } },
        };
        let pos = { truck^.pos, 2 };
        let draw_layer = (.offset, .layer, .rotation) => (
            let origin = (
                # recalculate from aseprite coords to unit quad coords
                let { x, y } = Vec2.vdiv(layer.origin, sheet.image_size);
                { x * 2 - 1, 1 - y * 2 }
            );
            let pos = Vec2.add(Vec2.add(pos, offset), Vec2.vmul(origin, { 4, 2 }));
            Sheet.draw_layer(
                sheet,
                .pos,
                .layer,
                .scale = 2,
                .flip = false,
                .rotation
            );
        );
        let wheel_rot = truck^.animation.wheel_rot;
        draw_layer(
            .offset = { 0, Float32.sin(wheel_rot * 10) * 0.02 },
            .layer = layers.body,
            .rotation = (
                let x = abs(truck^.vel) / SPEED * 2 - 1;
                let x = 1 - abs(x);
                Float32.pow(x, 0.5) * degree_to_rad(3)
            ),
        );
        draw_layer(
            .offset = { 0, 0 },
            .layer = layers.wheel1,
            .rotation = wheel_rot,
        );
        draw_layer(
            .offset = { 0, 0 },
            .layer = layers.wheel2,
            .rotation = wheel_rot,
        );
        draw_layer(
            .offset = { 0, 0 },
            .layer = layers.wheel3,
            .rotation = wheel_rot,
        );
    );
);
