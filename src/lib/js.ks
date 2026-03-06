import "./js_syntax.ks";
use (import "./la.ks").*;

module:

const Any = @opaque_type;

const unsafe_cast = [T, U] (a :: T) -> U => (
    @js_call "x=>x"(a)
);

const from_any = [T] (any :: Any) -> T => (
    @js_call "x=>x"(any)
);

const into_any = [T] (any :: T) -> Any => (
    @js_call "x=>x"(any)
);

const is_null = (x :: Any) -> Bool => (
    @js_call "x=>(x===null)"(x)
);

const check_null = [T] (a :: Any) -> Option.t[T] => (
    if a |> is_null then (
        :None
    ) else (
        :Some (a |> from_any)
    )
);

const List = (
    module:
    
    const t = [T] @opaque_type;
    
    const new = [T] () -> t[T] => (
        @native "[]"
    );
    const push = [T] (list :: t[T], x :: T) -> () => (
        @js_call list."push"(x)
    );
    const iter = [T] (list :: t[T]) -> std.iter.Iterable[T] => {
        .iter = f => (
            (@native "async(ctx,{list,f})=>{for(const x of list){await f(ctx,x)}}")(
                .list,
                .f,
            );
        ),
    };
    const filter = [T] (list :: t[T], predicate :: T -> Bool) -> t[T] => (
        let mut result = new();
        for e in iter(list) do (
            if predicate(e) then push(result, e);
        );
        result
    );
);

const Obj = (
    module:
    
    const t = [T] @opaque_type;
    
    const iter = [T] (obj :: t[T]) -> std.iter.Iterable[type { String, T }] => {
        .iter = f => (
            (@native "async(ctx,{obj,f})=>{for(const [key,value]of Object.entries(obj)){await f(ctx,{0:key,1:value})}}")(
                .obj,
                .f,
            );
        ),
    };
);

const json_parse = [T] (json :: String) -> T => (
    @js_call "JSON.parse"(json)
);

const new_float32_array = (data :: List.t[Float32]) -> Any => (
    (@native "(ctx,data)=>new Float32Array(data)")(data)
)
