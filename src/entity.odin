package game

import sdl "vendor:sdl2"

vec :: struct { x : f32, y : f32}

Entity_Type :: enum
{
    none = 0,
    Player,
    Monster,
    ground
} 

Entity :: struct
{
    valid : bool,
    pos   : vec,
    size  : vec,
    color : sdl.Color,
    tex   : ^sdl.Texture,
    dest  : sdl.Rect
}



Player :: struct
{
    movement : vec,
    using entity: Entity,
}


