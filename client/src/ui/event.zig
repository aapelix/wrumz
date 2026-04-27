pub const MouseButton = enum { left, right, middle };

pub const UiEvent = union(enum) {
    /// Mouse moved to canvas position (x, y).
    mouse_move: struct { x: f32, y: f32 },

    /// Mouse button pressed at canvas position.
    mouse_down: struct { x: f32, y: f32, button: MouseButton },

    /// Mouse button released at canvas position.
    mouse_up: struct { x: f32, y: f32, button: MouseButton },

    /// A printable character was typed (UTF-8 code point as u21).
    text_input: u21,

    /// Special key pressed (backspace, return, escape, …).
    key_down: Key,

    /// Focus moved away from this widget (call widget.blur()).
    blur,
};

pub const Key = enum {
    backspace,
    @"return",
    escape,
    left,
    right,
    home,
    end,
    delete,
    tab,
    other,
};
