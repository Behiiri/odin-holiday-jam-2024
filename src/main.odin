package game

import "core:fmt"

import sdl "vendor:sdl2"
import sdl_image "vendor:sdl2/image"

WINDOW_X :: 640
WINDOW_Y :: 420
TILE_W :: 16
TILE_H :: 16

MAX_ENTITY :: ((WINDOW_X / TILE_W) + 1) * ((WINDOW_Y / TILE_H) + 1)

World :: struct
{
    entities   : [MAX_ENTITY]Entity,
    tiles_in_x : f32,
    tiles_in_y : f32,
    scroll_pos : int,
    player     : Entity,
}

Game :: struct
{
    window   : ^sdl.Window,
    renderer : ^sdl.Renderer
}

Sprite_Type :: enum
{
    Player,
    ground_top,
    ground_soil,
}

Sprite_Asset :: struct
{
    type : Sprite_Type,
    path : string
}

sprite_files : []Sprite_Asset =
    {
        {Sprite_Type.Player, "../dat/art/player.png"},
        {Sprite_Type.Player, "../dat/map/map001.png"}
    }

get_sprite_file_path :: proc(st : Sprite_Type) -> string
{
    for s in sprite_files {
        if(s.type == st) {
            return s.path;
        }
    }
    
    return sprite_files[0].path;
}

surface_player : ^sdl.Surface
texture_player : ^sdl.Texture


init :: proc(game : ^Game) -> World
{
    fmt.println("MAX_ENTITY =", MAX_ENTITY)
    world := World{}
    world.tiles_in_x = WINDOW_X / TILE_W
    world.tiles_in_y = WINDOW_Y / TILE_H
    fmt.println("tiles_in_x =", world.tiles_in_x)
    fmt.println("tiles_in_y =", world.tiles_in_y)

    texture_player = sdl_image.LoadTexture(game.renderer, "../dat/art/player.png")
    assert(texture_player != nil, "texture_player failed to load")

    world.player.tex = texture_player
    
    for i := 1; i < MAX_ENTITY; i+=1 {
        world.entities[i] = Entity{}
        world.entities[i].valid = false
    }
    return world
}

update :: proc()
{

}

draw :: proc(renderer : ^sdl.Renderer, world : ^World)
{
    sdl.SetRenderDrawColor(renderer, 0, 100, 100, 255)
    rect : sdl.Rect = { 200, 200, 120, 120 }
    sdl.RenderDrawRect(renderer, &rect)

    sdl.RenderCopy(renderer, world.player.tex, nil, world.player.dest)
    
    sdl.SetRenderDrawColor(renderer, 0, 100, 200, 255)
}


main :: proc()
{
    game : Game
    
    game.window = sdl.CreateWindow(
        "game",
        sdl.WINDOWPOS_CENTERED, sdl.WINDOWPOS_CENTERED,
        640, 420,
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
        end_time : u64

        dt := get_timestep(1.0 / 60.0 / 8.0)

        if dt > 0.075 {
            dt = 0.075;
        }

        if(sdl.PollEvent(&event)) {
            if(event.type == sdl.EventType.QUIT) {
                break gameloop
            }

            if(event.type == sdl.EventType.KEYDOWN) {
                if(event.key.keysym.scancode == .ESCAPE) {
                    break gameloop
                }    
            }
        }
        rend := game.renderer
        
        sdl.RenderClear(rend)
        draw(rend, &world)
        sdl.RenderPresent(rend)
        
        end = cast(f32)sdl.GetTicks() / 1000.0
        // fmt.println("dt : ", 1.0 / (end - start))
    }
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
    }

    return 0
}
