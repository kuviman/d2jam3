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
        .scale,
        .rotation,
        .flip,
    ) => (
        let origin = (
            # recalculate from aseprite coords to unit quad coords
            let { x, y } = Vec2.vdiv(layer.origin, sheet.image_size);
            { x * 2 - 1, 1 - y * 2 }
        );
        let aspect = sheet.image_size.0 / sheet.image_size.1;
        geng.draw_quad_ext(
            .model_matrix = Mat3.translate(pos)
                |> Mat3.mul_mat(Mat3.rotate(rotation))
                |> Mat3.mul_mat(
                    Mat3.scale(Vec2.mul({ (if flip then -1 else 1) * aspect, 1 }, scale))
                ) |> Mat3.mul_mat(Mat3.translate(Vec2.neg(origin))),
            .texture = sheet.texture,
            .uv = {
                .bottom_left = Vec2.add(
                    { 0, layer.idx / sheet.total_layers },
                    sheet.pixel_size,
                ),
                .size = sheet.layer_uv_size,
            },
            .color = { 1, 1, 1, 1 },
        );
    );
);
