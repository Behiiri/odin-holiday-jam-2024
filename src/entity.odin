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
    velocity : vec,
    is_yumping    : bool,
    looking_right : bool,
    using entity: Entity,
}


/* tile_to_world_pos :: proc(x : int, y : int) -> vec */
/* { */
/*     return vec {cast(f32)TILE_W * cast(f32)x, cast(f32)TILE_H * cast(f32)y} */
/* } */
