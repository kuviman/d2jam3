const Seed = newtype {
    .target :: Float32,
    .t :: Float32,
    .plant_type :: PlantType,
};

let texture = assets.load_texture(
    "seed.png",
);

impl Seed as module = (
    module:
    
    const RADIUS = std.op.div[Float32](1, 4);
    const TIME = 1;
    
    const new = (plant_type) -> Seed => {
        .target = std.random.gen_range(
            .min = -PLAYABLE_AREA,
            .max = +PLAYABLE_AREA,
        ),
        .t = 0,
        .plant_type,
    };
    
    const update = (self :: &mut Seed, dt :: Float32) => (
        self^.t += dt / TIME;
    );
    
    const draw = (self :: &Seed) => (
        let t = self^.t;
        let pos = {
            t * self^.target + (1 - t) * 7,
            (1 - sqr(t * 2 - 1)) * 4 + (1 - t) * 2
        };
        geng.draw_quad_ext(
            .model_matrix = Mat3.translate(pos)
                |> Mat3.mul_mat(Mat3.rotate(t * 10))
                |> Mat3.mul_mat(Mat3.scale({ RADIUS, RADIUS })),
            .texture,
            .uv = Rect.UNIT,
        );
    );
);
