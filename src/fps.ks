const FpsCounter = newtype {
    .frames :: Float32,
    .time :: Float32,
    .fps :: Float32,
};

impl FpsCounter as module = (
    module:

    const new = () -> FpsCounter => {
        .frames = 0,
        .time = 0,
        .fps = 0,
    };

    const frame = (self :: &mut FpsCounter, dt :: Float32) => (
        self^.time += dt;
        self^.frames += 1;
        if self^.time > 1 then (
            self^.fps = self^.frames / self^.time;
            self^.frames = 0;
            self^.time = 0;
        );
    );

    const draw = (self :: &FpsCounter) => (
        with geng.CameraCtx = geng.CameraUniforms.init(
            { .pos = { 0, 0 }, .fov = 30 },
            .framebuffer_size = (@current geng.CameraCtx).framebuffer_size,
        );
        let text = "FPS: " + to_string(Float32.round(self^.fps));
        font.Font.draw(
            &assets.font,
            text,
            .pos = { 0, 14 },
            .size = 1,
            .color = { 0, 0, 0, 1 },
            .align = 0.5,
        );
    );
);