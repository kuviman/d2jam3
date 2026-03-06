use (import "./la.ks").*;
const js = import "./js.ks";

@syntax "js_call" 30 @wrap never = "@js_call" " " js _=(@wrap if_any "(" ""/"\n\t" args:any ""/"\\\n" ")");
impl syntax (@js_call js(args)) = `(
    (@native ("async(ctx,...args)=>{return await(" + $js + ")(...args)}"))($args)
);
@syntax "js_call_method" 30 @wrap never = "@js_call" " " obj "." js _=(@wrap if_any "(" ""/"\n\t" args:any ""/"\\\n" ")");
impl syntax (@js_call obj.js(args)) = `(
    (@native ("async(ctx,o,...args)=>{return await o." + $js + "(...args)}"))($obj, ...{ $args })
);

module:

const HtmlElement = @opaque_type;

const HtmlCanvasElement = @opaque_type;

impl HtmlCanvasElement as module = (
    module:
    
    const get_context = (
        canvas :: HtmlCanvasElement,
        context_type :: String,
    ) -> js.Any => (
        @js_call canvas."getContext"(context_type)
    );
    
    const set_width = (
        canvas :: HtmlCanvasElement,
        width :: Int32,
    ) -> () => (
        @js_call "({canvas,width})=>{canvas.width=width}"(
            { .canvas, .width }
        )
    );
    
    const set_height = (
        canvas :: HtmlCanvasElement,
        height :: Int32,
    ) -> () => (
        @js_call "({canvas,height})=>{canvas.height=height}"(
            { .canvas, .height }
        )
    );
);

const HtmlDocumentElement = @opaque_type;

impl HtmlDocumentElement as module = (
    module:
    
    const get_element_by_id = (
        document :: HtmlDocumentElement,
        id :: String,
    ) -> HtmlElement => (
        @js_call document."getElementById"(id)
    );
);

const document = () -> HtmlDocumentElement => (
    @native "document"
);

const WebGLRenderingContext = @opaque_type;

const HtmlImageElement = newtype {
    .naturalWidth :: Float32,
    .naturalHeight :: Float32,
};
