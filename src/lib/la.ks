import "./js_syntax.ks";

module:

impl Float64 as module = (
    module:
    
    const PI :: Float64 = 3.1415;
    
    const sin = (x :: Float64) -> Float64 => (
        @js_call "Math.sin"(x)
    );
    const cos = (x :: Float64) -> Float64 => (
        @js_call "Math.cos"(x)
    );
    const sqrt = (x :: Float64) -> Float64 => (
        @js_call "Math.sqrt"(x)
    );
    const atan2 = (y :: Float64, x :: Float64) -> Float64 => (
        @js_call "Math.atan2"(y, x)
    );
    
    const sin_cos = (x :: Float64) -> { Float64, Float64 } => (
        { sin(x), cos(x) }
    );
);

const Float32 = Float64;

const Vec2 = newtype { Float32, Float32 };

impl Vec2 as module = (
    module:
    const neg = (v :: Vec2) -> Vec2 => { -v.0, -v.1 };
    const add = (a :: Vec2, b :: Vec2) -> Vec2 => (
        { a.0 + b.0, a.1 + b.1 }
    );
    const sub = (a :: Vec2, b :: Vec2) -> Vec2 => (
        { a.0 - b.0, a.1 - b.1 }
    );
    const mul = (v :: Vec2, k :: Float32) -> Vec2 => (
        { v.0 * k, v.1 * k }
    );
    const div = (v :: Vec2, k :: Float32) -> Vec2 => (
        { v.0 / k, v.1 / k }
    );
    const vmul = (a :: Vec2, b :: Vec2) -> Vec2 => (
        { a.0 * b.0, a.1 * b.1 }
    );
    const vdiv = (a :: Vec2, b :: Vec2) -> Vec2 => (
        { a.0 / b.0, a.1 / b.1 }
    );
    
    const rotate = (v :: Vec2, a :: Float32) -> Vec2 => (
        let { sin, cos } = Float32.sin_cos(a);
        {
            v.0 * cos - v.1 * sin,
            v.0 * sin + v.1 * cos,
        }
    );
    
    const map = (v :: Vec2, f :: Float32 -> Float32) -> Vec2 => (
        { f(v.0), f(v.1) }
    );
    
    const dot = (a :: Vec2, b :: Vec2) -> Float32 => (
        a.0 * b.0 + a.1 * b.1
    );
    
    const len2 = (v :: Vec2) -> Float32 => dot(v, v);
    const len = (v :: Vec2) -> Float32 => Float32.sqrt(len2(v));
    
    const arg = (v :: Vec2) -> Float32 => (
        Float32.atan2(v.1, v.0)
    );
);

const Vec3 = newtype { Float32, Float32, Float32 };

impl Vec3 as module = (
    module:
    
    const dot = (a :: Vec3, b :: Vec3) -> Float32 => (
        a.0 * b.0 + a.1 * b.1 + a.2 * b.2
    );
);

const Vec4 = newtype { Float32, Float32, Float32, Float32 };

const Mat3 = newtype { Vec3, Vec3, Vec3 };

impl Mat3 as module = (
    module:
    
    const transpose = (m :: Mat3) -> Mat3 => {
        { m.0.0, m.1.0, m.2.0 },
        { m.0.1, m.1.1, m.2.1 },
        { m.0.2, m.1.2, m.2.2 },
    };
    
    const div = (m :: Mat3, k :: Float32) -> Mat3 => {
        { m.0.0 / k, m.0.1 / k, m.0.2 / k },
        { m.1.0 / k, m.1.1 / k, m.1.2 / k },
        { m.2.0 / k, m.2.1 / k, m.2.2 / k },
    };
    
    const mul_mat = (a :: Mat3, b :: Mat3) -> Mat3 => (
        let b = transpose(b);
        const dot = Vec3.dot;
        let result = {
            { dot(a.0, b.0), dot(a.0, b.1), dot(a.0, b.2) },
            { dot(a.1, b.0), dot(a.1, b.1), dot(a.1, b.2) },
            { dot(a.2, b.0), dot(a.2, b.1), dot(a.2, b.2) },
        };
        # dbg.print(.a, .b, .result);
        result
    );
    
    const inverse = (m :: Mat3) -> Mat3 => (
        let {
            { a00, a01, a02 },
            { a10, a11, a12 },
            { a20, a21, a22 },
        } = m;
        
        let b01 = a22 * a11 - a12 * a21;
        let b11 = -a22 * a10 + a12 * a20;
        let b21 = a21 * a10 - a11 * a20;
        
        let det = a00 * b01 + a01 * b11 + a02 * b21;
        
        div(
            {
                { b01, -a22 * a01 + a02 * a21, a12 * a01 - a02 * a11 },
                { b11, a22 * a00 - a02 * a20, -a12 * a00 + a02 * a10 },
                { b21, -a21 * a00 + a01 * a20, a11 * a00 - a01 * a10 },
            },
            det
        )
    );
    
    const mul_vec = (m :: Mat3, v :: Vec3) -> Vec3 => (
        # dbg.print("BEFORE MUL", .m, .v);
        let result = {
            Vec3.dot(m.0, v),
            Vec3.dot(m.1, v),
            Vec3.dot(m.2, v),
        };
        # dbg.print(.m, .v, .result);
        result
    );
    
    const translate = ({ dx, dy } :: Vec2) -> Mat3 => {
        { 1, 0, dx },
        { 0, 1, dy },
        { 0, 0, 1 },
    };
    
    const scale = ({ sx, sy } :: Vec2) -> Mat3 => {
        { sx, 0, 0 },
        { 0, sy, 0 },
        { 0, 0, 1 },
    };
    
    const rotate = (a :: Float32) -> Mat3 => (
        let { sin, cos } = Float32.sin_cos(a);
        {
            { cos, -sin, 0 },
            { sin, cos, 0 },
            { 0, 0, 1 },
        }
    );
);

const Rect = newtype {
    .bottom_left :: Vec2,
    .size :: Vec2,
};

impl Rect as module = (
    module:
    
    const UNIT :: Rect = {
        .bottom_left = { 0, 0 },
        .size = { 1, 1 },
    };
);
