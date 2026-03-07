const Tree = newtype {
    .pos :: Vec2,
    .growth :: Float32,
    
    .animation :: {
        
    
    },
};

let sheet = Sheet.load("assets/textures/tree/sheet.png", .total_layers = 5);

impl Tree as module = (
    module:
    
    const GROWTH_SPEED = 0.1;
    
    const new = (pos) -> Tree => {
        .pos,
        .growth = 0,
        .animation = {
            
        
        },
    };
    
    const update = (tree :: &mut Tree, dt :: Float64) => (
        tree^.growth = min(tree^.growth + GROWTH_SPEED * dt, 1);
    );
    
    const draw = (tree :: &Tree) => (
        const layers = {
            .trunk = { .idx = 4, .origin = { 32, 64 } },
            .leaves1 = { .idx = 3, .origin = { 15, 32 } },
            .leaves2 = { .idx = 2, .origin = { 47, 34 } },
            .leaves3 = { .idx = 1, .origin = { 41, 13 } },
        };
        const MAX_SCALE = 2;
        let scale = tree^.growth * MAX_SCALE;
        let scale_leaves = sqr(tree^.growth) * MAX_SCALE;
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
        draw_layer(
            sheet,
            .layer = layers.leaves1,
            .rotation = 0,
            .scale = scale_leaves,
        );
        draw_layer(
            sheet,
            .layer = layers.leaves2,
            .rotation = 0,
            .scale = scale_leaves,
        );
        draw_layer(
            sheet,
            .layer = layers.leaves3,
            .rotation = 0,
            .scale = scale_leaves,
        );
    )
);
