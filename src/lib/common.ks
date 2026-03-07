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

const clamp_abs = (x :: Float32, .max_abs :: Float32) -> Float32 => (
    clamp(x, .min = -max_abs, .max = +max_abs)
);

const degree_to_rad = (a :: Float32) -> Float32 => (
    a * (@eval Float32.PI / 180)
);

const normalize_angle_pi = (mut x) => (
    while x > Float32.PI do (
        x -= 2.0 * Float32.PI;
    );
    while x < -Float32.PI do (
        x += 2.0 * Float32.PI;
    );
    x
);

const add_to_angle = (x, dx) => (
    x^ += dx;
    x^ = normalize_angle_pi(x^);
);

const min_by_key = [T, K] (
    iter :: std.iter.Iterable[T],
     f :: T -> K,
) -> Option.t[T] => (
    let mut min_el = :None;
    for value in iter do (
        let key = f(value);
        let update = match min_el with (
            | :None => true
            | :Some min_el => key < min_el.key
        );
        if update then (
            min_el = :Some { .value, .key };
        );
    );
    min_el |> Option.map(x => x.value)
);

const sqr = (x :: Float32) -> Float32 => x * x;

const or_else = [T] (
    opt :: Option.t[T],
    f :: () -> Option.t[T],
) -> Option.t[T] => (
    match opt with (
        | :None => f()
        | :Some _ => opt
    )
);