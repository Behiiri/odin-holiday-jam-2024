package game

import "core:fmt"
import "core:mem"
import "core:math"

import sdl "vendor:sdl2"
import sdl_image "vendor:sdl2/image"

WINDOW_X :: 640 * 2
WINDOW_Y :: 420 * 2
TILE_W :: 21 * 2
TILE_H :: 21 * 2

MAX_ENTITY :: ((WINDOW_X / TILE_W) + 1) * ((WINDOW_Y / TILE_H) + 1)

Game :: struct
{
    window   : ^sdl.Window,
    renderer : ^sdl.Renderer
}

World :: struct
{
    entities   : [MAX_ENTITY]Entity,
    tiles_in_x : f32,
    tiles_in_y : f32,
    scroll_pos : f32,
    player     : Player,
    tilemap    : [dynamic]Sprite_Type,
    map_width  : int,
    map_height : int,
}

Sprite_Type :: enum
{
    none = 0,
    player,
    map001,
    ground_top,
    ground_soil,
    temp,
    not_found
}

Sprite_Asset :: struct
{
    type : Sprite_Type,
    path : cstring
}

sprite_files : []Sprite_Asset =
    {
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

tile_index_to_Pos_x :: proc(i : int)
{
    
}

tile_to_world_pos :: proc(x : int, y : int) -> vec
{
    return vec {cast(f32)TILE_W * cast(f32)x, cast(f32)TILE_H * cast(f32)y}
}

init :: proc(game : ^Game) -> World
{
    world := World{}
    world.tiles_in_x = WINDOW_X / TILE_W
    world.tiles_in_y = WINDOW_Y / TILE_H

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
    world.player.dest = sdl.Rect{100, 100, 50, 50}
    
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

    world.tilemap = make([dynamic]Sprite_Type, w*h, 4096)

    for i in 0..< w * h { 
        r, g, b, a : u8 = 0, 0, 0, 0;
        sdl.GetRGBA(pixels^, map_surface.format, &r, &g, &b, &a);
        pixels = mem.ptr_offset(pixels, 1);
        // fmt.println("pixel =", i, "(rgb) = ", r, g, b, a);
        tile_type := get_tile_type(r, g, b)
        if(tile_type == .player) {
            tile_index_x := i % world.map_width;
            tile_index_y := i / world.map_width;
            world.player.pos = {(f32)(tile_index_x * TILE_W), (f32)((tile_index_y * TILE_H))}
        } else {
            world.tilemap[i] = tile_type
        }
    }

    return world
}

update :: proc(world : ^World, dt : f32)
{
    speed : f32 = TILE_W * 8;
    //world.player.pos.x += world.player.movement.x * dt * speed
    //world.player.pos.y += world.player.movement.y * dt * speed
    world.scroll_pos += world.player.movement.x * dt * speed
    if world.scroll_pos < 0 {
        world.scroll_pos = 0
    }
    
}

draw :: proc(renderer : ^sdl.Renderer, world : ^World)
{
    sdl.SetRenderDrawColor(renderer, 0, 100, 100, 255)
    leftmost_tile  := world.scroll_pos / TILE_W
    rightmost_tile := (world.scroll_pos + WINDOW_X) / TILE_W

     // TODO calulate the index of tiles that will be drawn and use it
    for i in 0..< len(world.tilemap) {
        tile_x := i % world.map_width
        if leftmost_tile > cast(f32)tile_x + 1 || rightmost_tile < cast(f32)tile_x {
            continue
        }
        tile_y := i / world.map_width

        tex := sprites[world.tilemap[i]]
        x := cast(i32)tile_x*TILE_W
        y := cast(i32)tile_y*TILE_H
        dest : sdl.Rect = {(x - cast(i32)world.scroll_pos), y, TILE_W, TILE_H}
        sdl.RenderCopy(renderer, tex, nil, &dest)
    }

    player_pos : sdl.Rect = { cast(i32)world.player.pos.x, cast(i32)world.player.pos.y, 32, 32 }
    sdl.RenderCopy(renderer, world.player.tex, nil, &player_pos)    
    
    sdl.SetRenderDrawColor(renderer, 0, 100, 200, 255)
}

main :: proc()
{
    game : Game
    
    game.window = sdl.CreateWindow(
        "game",
        sdl.WINDOWPOS_CENTERED, sdl.WINDOWPOS_CENTERED,
        WINDOW_X, WINDOW_Y,
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

        dt := get_timestep(1.0 / 6000.0)
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
                        //world.player.movement.y = 0;
                        //world.player.movement.y -= 1;
                    }
                    case .A : {
                        world.player.movement.x = 0;
                        world.player.movement.x -= 1;
                    }
                    case .S : {
                        //world.player.movement.y = 0;
                        //world.player.movement.y += 1;

                    }
                    case .D : {
                        world.player.movement.x = 0;
                        world.player.movement.x += 1;
                    }

                    case .SPACE : {
                        
                    }
                }
            }

            if(event.type == sdl.EventType.KEYUP) {
                #partial switch(event.key.keysym.scancode) {
                    case .ESCAPE : {
                        break gameloop
                    }
                    case .W : {
                        //world.player.movement.y = 0;
                    }
                    case .A : {
                        world.player.movement.x = 0;
                    }
                    case .S : {
                        //world.player.movement.y = 0;

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
