module:

use (import "./la.ks").*;
const js = import "./js.ks";
const web = import "./web.ks";

const fetch_string = (path :: String) -> String => (
    (@native "Runtime.fetch_string")(path)
);

const time = (
    module:
    
    const now = () -> Float64 => (
        (@native "performance.now()") / 1000
    );
);

const load_image = (url :: String) -> web.HtmlImageElement => (
    (@native "Runtime.load_image")(url)
);

const await_animation_frame = () -> () => (
    (@native "Runtime.await_animation_frame")()
);

const abs = (x :: Float32) -> Float32 => (
    if x < 0 then (
        -x
    ) else (
        x
    )
);

const min = (a :: Float32, b :: Float32) -> Float32 => (
    if a < b then a else b
);

const max = (a :: Float32, b :: Float32) -> Float32 => (
    if a > b then a else b
);

const clamp = (x :: Float32, .min :: Float32, .max :: Float32) -> Float32 => (
    if x < min then min else if x > max then max else x
);
