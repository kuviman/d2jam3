const asset = import "./asset.ks";

module:

const ContextT = @opaque_type;

const Context = @context ContextT;

const init = () -> ContextT => (
    (@native "Runtime.audio.init")()
);

const load = (path) -> Buffer => (
    let ctx = (@current Context);
    (@native "Runtime.audio.load")(.ctx, .path)
);

const PlayOptions = newtype {
    .@"loop" :: Bool,
    .gain :: Float64,
};

impl PlayOptions as module = (
    module:
    
    const default = () -> PlayOptions => {
        .@"loop" = false,
        .gain = 1,
    };
);

const play_with = (buffer :: Buffer, options :: PlayOptions) -> () => (
    let ctx = (@current Context);
    (@native "Runtime.audio.play")(.ctx, .buffer, .options)
);

const play = (buffer :: Buffer) => (
    play_with(buffer, PlayOptions.default())
);

const set_master_volume = (volume :: Float64) -> () => (
    let ctx = (@current Context);
    (@native "Runtime.audio.set_master_volume")(.ctx, .volume)
);

const Buffer = @opaque_type;

impl Buffer as asset.Load = {
    .load,
    .default_ext = :Some "wav",
};