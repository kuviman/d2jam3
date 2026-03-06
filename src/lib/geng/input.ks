use (import "../common.ks").*;

use std.collections.Queue;

module:

const raw = (
    module:
    
    const MouseEvent = newtype {
        .button :: Int32,
    };
    
    const PointerEvent = MouseEvent;
);

const ContextT = newtype {
    .runtime :: @opaque_type,
    .events :: Queue.t[Event],
};
const Context = @context ContextT;

const init = (canvas :: web.HtmlCanvasElement) -> ContextT => (
    let mut events = Queue.new();
    let runtime = (@native "Runtime.input.init")(
        .canvas,
        .mouse_press = (e :: raw.MouseEvent) => (
            if MouseButton.from_raw(e.button) is :Some (button) then (
                Queue.push(&mut events, :MousePress { .button });
            );
        ),
        .pointer_press = (e :: raw.PointerEvent, pos :: Vec2) => (
            Queue.push(&mut events, :PointerPress { .pos });
        ),
    );
    {
        .runtime,
        .events,
    }
);

const Key = newtype (
    | :ArrowLeft
    | :ArrowRight
    | :ArrowUp
    | :ArrowDown
    | :Space
);

impl Key as module = (
    module:
    
    const is_pressed = (key :: Key) -> Bool => (
        (@native "Runtime.input.is_key_pressed")(key)
    );
);

const MouseButton = newtype (
    | :Left
    | :Middle
    | :Right
);

impl MouseButton as module = (
    module:
    
    const from_raw = (raw :: Int32) -> Option.t[MouseButton] => (
        if raw == 0 then (
            :Some (:Left)
        ) else if raw == 1 then (
            :Some (:Middle)
        ) else if raw == 2 then (
            :Some (:Right)
        ) else (
            :None
        )
    );
    
    const into_raw = (button :: MouseButton) -> Int32 => (
        match button with (
            | :Left => 0
            | :Middle => 1
            | :Right => 2
        )
    );
    
    const is_pressed = (button :: MouseButton) -> Bool => (
        (@native "Runtime.input.is_mouse_button_pressed")(
            into_raw(button)
        )
    );
);

const Event = newtype (
    | :MousePress { .button :: MouseButton }
    | :PointerPress { .pos :: Vec2 }
);

const iter_events = () -> std.iter.Iterable[Event] => (
    let mut ctx = (@current Context);
    {
        .iter = consumer => (
            while Queue.length(&ctx.events) > 0 do (
                let event = Queue.pop(&mut ctx.events);
                consumer(event);
            );
        ),
    }
);

const is_any_pointer_pressed = () -> Bool => (
    (@native "Runtime.input.is_any_pointer_pressed")()
);
