@syntax "js_call" 30 @wrap never = "@js_call" " " js _=(@wrap if_any "(" ""/"\n\t" args:any ""/"\\\n" ")");
impl syntax (@js_call js(args)) = `(
    (@native ("async(ctx,...args)=>{return await(" + $js + ")(...args)}"))($args)
);
@syntax "js_call_method" 30 @wrap never = "@js_call" " " obj "." js _=(@wrap if_any "(" ""/"\n\t" args:any ""/"\\\n" ")");
impl syntax (@js_call obj.js(args)) = `(
    (@native ("async(ctx,o,...args)=>{return await o." + $js + "(...args)}"))($obj, ...{ $args })
);