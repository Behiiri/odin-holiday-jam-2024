package game

import "core:fmt"
import "core:mem"
import "core:math"

import sdl "vendor:sdl2"
import sdl_image "vendor:sdl2/image"

SCREEN_X :: 640 * 2
SCREEN_Y :: 420 * 2
ROWS     :: 10 // number of visible rows in the screen
TILE_H   :: SCREEN_Y / ROWS
TILE_W   :: TILE_H

GRAVITY :: 0.4
YUMP_STRENGTH :: -16

MAX_ENTITY :: ((SCREEN_X / TILE_W) + 1) * ((SCREEN_Y / TILE_H) + 1)

Game :: struct
{
    window   : ^sdl.Window,
    renderer : ^sdl.Renderer
}

World :: struct
{
    entities   : [MAX_ENTITY]Entity,
    player     : Player,
    tilemap    : [dynamic]Sprite_Type,
    map_width  : int,
    map_height : int,
    scroll_pos : vec,
}

Sprite_Type :: enum
{
    none = 0,
    player,
    map001,
    ground_top,
    ground_soil,
    not_found
}

Sprite_File :: struct
{
    type : Sprite_Type,
    path : cstring
}

sprite_files : []Sprite_File =
    {
        {Sprite_Type.not_found,      "../dat/art/player.png"}, // TODO change png
        {Sprite_Type.player,         "../dat/art/player.png"},
        {Sprite_Type.map001,         "../dat/map/map001.png"},
        {Sprite_Type.ground_soil,    "../dat/art/ground_soil.png"},
        {Sprite_Type.ground_top,     "../dat/art/ground_top.png"},
    }

Sprite :: struct
{
    type : Sprite_Type,
    tex  : ^sdl.Texture,
}

sprites : map[Sprite_Type]^sdl.Texture

Color_Sprite_Mapping :: struct
{
    r, g, b : u8,
    sprite_type : Sprite_Type
}

color_mapping := []Color_Sprite_Mapping {

    {255, 255, 255,   Sprite_Type.none},
    {255, 255, 0,     Sprite_Type.player},
    {143, 86,  59,    Sprite_Type.ground_soil},
    {102, 57,  49,    Sprite_Type.ground_top},
}

get_sprite_path :: proc(st : Sprite_Type) -> cstring
{
    for s in sprite_files {
        if(s.type == st) {
            return s.path;
        }
    }
    
    return sprite_files[0].path;
}

get_tile_type :: proc(r : u8, g : u8, b : u8) -> Sprite_Type
{
    for i in 0..<len(color_mapping) {
        if color_mapping[i].r == r && color_mapping[i].g == g && color_mapping[i].b == b {
            return color_mapping[i].sprite_type
        }    
    }
    
    return Sprite_Type.not_found;
}

init :: proc(game : ^Game) -> World
{
    world := World{}

    sprites = make(map[Sprite_Type]^sdl.Texture)

    for sprite_file in sprite_files { // TODO only load texture in a level
        tex := sdl_image.LoadTexture(game.renderer, sprite_file.path)
        assert(tex != nil, "texture failed to load")
        sprites[sprite_file.type] = tex
        fmt.println("loaded sprite:", sprite_file.type);
    }

    surface_player : ^sdl.Surface
    texture_player : ^sdl.Texture
    
    world.player.tex = sprites[Sprite_Type.player]

    for i := 1; i < MAX_ENTITY; i+=1 {
        world.entities[i] = Entity{}
        world.entities[i].valid = false
    }

    map_surface := sdl_image.Load(get_sprite_path(Sprite_Type.map001))
    pixels := cast(^u32)(map_surface.pixels)

    w := cast(int)map_surface.w
    h := cast(int)map_surface.h
    world.map_width  = w
    world.map_height = h

    world.tilemap = make([dynamic]Sprite_Type, w*h, 8196)

    for i in 0..< w * h { 
        r, g, b, a : u8 = 0, 0, 0, 0;
        sdl.GetRGBA(pixels^, map_surface.format, &r, &g, &b, &a);
        pixels = mem.ptr_offset(pixels, 1);
        tile_type := get_tile_type(r, g, b)
        
        if(tile_type == .player) {
            tile_index_x := i % world.map_width;
            tile_index_y := i / world.map_width;
            world.player.pos = {(f32)(tile_index_x * TILE_W), cast(f32)((tile_index_y) * TILE_H)}
        } else {
            world.tilemap[i] = tile_type
        }
    }   
    return world
}


update :: proc(world : ^World, dt : f32)
{
    speed : f32 = TILE_W * 8;

    delta_x := world.player.movement.x * dt * speed
    world.player.pos.x += delta_x
    world.player.pos.y += world.player.movement.y * dt * speed
    d : vec = {world.player.pos.x - SCREEN_X/2, world.player.pos.y - SCREEN_Y/2}

    if(!can_move_to(world)){
        world.player.pos.x -= delta_x
    }
        

    if world.player.looking_right == true {
        d.x += SCREEN_X/3 + TILE_H/2
    } else {
        d.x -= SCREEN_X/3 - TILE_H/2
    }
    
    animate_to_destination_vec(&world.scroll_pos, d, dt, 5)

    if world.scroll_pos.x < 0 {
        world.scroll_pos.x = 0;
    }

    if (world.player.is_yumping) {
        world.player.velocity.y += GRAVITY;
        world.player.pos.y += world.player.velocity.y;

    } else
    {
        world.player.velocity.y += GRAVITY/4*3;
        world.player.pos.y += world.player.velocity.y/4*3;
    }
    
    floor := get_floor_height(world.player.pos.x, world);
    if (world.player.pos.y >= floor) {
        world.player.pos.y = floor;
        world.player.is_yumping = false;
        world.player.velocity.y = 0;
    }

}

yump :: proc(player : ^Player)
{
    if !player.is_yumping {
        player.velocity.y = YUMP_STRENGTH;
        player.is_yumping = true;
    }
}


is_equals :: proc(a : f32, b : f32, epsilon : f32) -> bool
{
    return math.abs(a - b) <= epsilon;
}

animate_to_destination_f :: proc(f : ^f32, d : f32, dt : f32, t : f32) -> bool
{
    f^ += (d - f^) * (1.0 - math.pow(2.0, -t * dt));
    if (is_equals(f^, d, 0.5)) {
        f^ = d;
        return true;
    }
    return false;
}

animate_to_destination_vec :: proc(v : ^vec, d : vec, dt : f32, t : f32)
{
    animate_to_destination_f(&(v.x), d.x, dt, t);
    animate_to_destination_f(&(v.y), d.y, dt, t);
}

can_move_to :: proc(world : ^World) -> bool
{
    is_moving_right := world.player.looking_right
    // tile_column : int = cast(int)x / TILE_W;
    player_col  : int = cast(int)world.player.pos.x / TILE_W

    if player_col % world.map_width == 0  && !is_moving_right {
        return false
    }
    
    if player_col % world.map_width == world.map_width -1  && is_moving_right {
        return false
    }

    player_row  : int = cast(int)world.player.pos.y / TILE_H
    index := player_col + player_row * world.map_width
    if is_moving_right {
        index := player_col + player_row * world.map_width
        if  world.tilemap[index + 1] == .ground_soil ||
            world.tilemap[index + 1] == .ground_top {
                return false;
            }
    }
    
    if !is_moving_right {
        if  world.tilemap[index] == .ground_soil ||
            world.tilemap[index] == .ground_top {
                return false;
            }
    }

    return true;
}


get_floor_height :: proc(x : f32, world : ^World) -> f32
{
    tile_column : int = cast(int)x / TILE_W;
    player_row  : int = cast(int)world.player.pos.y / TILE_H

    for i := player_row; i < world.map_height; i += 1 {
        index : int = tile_column + world.map_width * (i);
        if(world.tilemap[index] == .ground_soil || world.tilemap[index] == .ground_top )
        {
            return TILE_H * cast(f32)(i - 1)
        }
    }
    
    
    return 30 * TILE_H
}

draw :: proc(renderer : ^sdl.Renderer, world : ^World)
{
    sdl.SetRenderDrawColor(renderer, 0, 150, 190, 255)
    
    leftmost_tile  := world.scroll_pos.x / TILE_W
    rightmost_tile := (world.scroll_pos.x + SCREEN_X) / TILE_W

    offset_y := cast(f32)ROWS * 0.6  * cast(f32)TILE_H
    // TODO calulate the index of tiles that will be drawn and use it
    for i in 0..< len(world.tilemap) {
        tile_x := i % world.map_width
        tile_y := i / world.map_width
        if leftmost_tile > cast(f32)tile_x + 1 || rightmost_tile < cast(f32)tile_x {
            continue
        }

        tex := sprites[world.tilemap[i]]
        x := cast(i32)tile_x*TILE_W
        y := cast(i32)tile_y*TILE_H
        dest : sdl.Rect = { x - cast(i32)world.scroll_pos.x,
                            y - cast(i32)world.scroll_pos.y,
                            TILE_W,
                            TILE_H }
        sdl.RenderCopy(renderer, tex, nil, &dest)
    }

    player_dest : sdl.Rect = { cast(i32)(world.player.pos.x - world.scroll_pos.x),
                               cast(i32)(world.player.pos.y - world.scroll_pos.y),
                               TILE_W,
                               TILE_H }
    sdl.RenderCopy(renderer, world.player.tex, nil, &player_dest)
}

main :: proc()
{
    game : Game
    
    game.window = sdl.CreateWindow(
        "game",
        sdl.WINDOWPOS_CENTERED, sdl.WINDOWPOS_CENTERED,
        SCREEN_X, SCREEN_Y,
        sdl.WINDOW_SHOWN)
    assert(game.window != nil, sdl.GetErrorString());
    
    game.renderer = sdl.CreateRenderer(game.window, -1, sdl.RENDERER_ACCELERATED)
    assert(game.renderer != nil, sdl.GetErrorString());

    event : sdl.Event

    start : f32
    end : f32

    world := init(&game)
        
    gameloop : for {
        start = cast(f32)sdl.GetTicks() / 1000.0
        
        start_time : u64
        end_time   : u64

        dt := get_timestep(1.0 / 60.0 / 2)
        //dt : f32 = end - start
        
        if dt > 0.075 {
            dt = 0.075;
        }

        // input
        if(sdl.PollEvent(&event)) {
            if(event.type == sdl.EventType.QUIT) {
                break gameloop
            }

            if(event.type == sdl.EventType.KEYDOWN) {
                #partial switch(event.key.keysym.scancode) {
                    case .ESCAPE : {
                        break gameloop
                    }
                    case .W : {
                        world.player.movement.y = 0;
                        //world.player.movement.y -= 1;
                    }
                    case .A : {
                        world.player.movement.x = 0;
                        world.player.movement.x -= 1;
                        world.player.looking_right = false;
                    }
                    case .S : {
                        world.player.movement.y = 0;
                        //world.player.movement.y += 1;

                    }
                    case .D : {
                        world.player.movement.x = 0;
                        world.player.movement.x += 1;
                        world.player.looking_right = true
                    }

                    case .SPACE : {
                        yump(&world.player)
                        
                    }
                }
            }

            if(event.type == sdl.EventType.KEYUP) {
                #partial switch(event.key.keysym.scancode) {
                    case .ESCAPE : {
                        break gameloop
                    }
                    case .W : {
                        world.player.movement.y = 0;
                    }
                    case .A : {
                        world.player.movement.x = 0;
                    }
                    case .S : {
                        world.player.movement.y = 0;

                    }
                    case .D : {
                        world.player.movement.x = 0;
                    }
                }
            }
        }

        update(&world, dt)

        rend := game.renderer
        sdl.RenderClear(rend)
        draw(rend, &world)
        sdl.RenderPresent(rend)
        
        end = cast(f32)sdl.GetTicks() / 1000.0
        // fmt.println("dt : ", 1.0 / (end - start))
    }

    // cleanup??
}

get_timestep :: proc(minimum_time : f32) -> f32
{
    delta_time : f32
    this_time  : f32
    @(static) last_time : f32 = -1

    if last_time == -1 {
        last_time = cast(f32)sdl.GetTicks() / 1000.0 - minimum_time
    }

    for {
        this_time = (cast(f32)sdl.GetTicks() / 1000.0)
        delta_time = cast(f32)(this_time - last_time)
        if delta_time >= minimum_time {
            last_time = this_time
            return delta_time
        }
        
        sdl.Delay(1); // TODO
    }

    return 0
}
