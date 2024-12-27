package main

import "core:fmt"

import sdl "vendor:sdl2"
import sdl_image "vendor:sdl2/image"

main :: proc() {
    window := sdl.CreateWindow(
        "game",
        sdl.WINDOWPOS_CENTERED, sdl.WINDOWPOS_CENTERED,
        640, 420,
        sdl.WINDOW_SHOWN)
    assert(window != nil, sdl.GetErrorString());
    
    renderer := sdl.CreateRenderer(window, -1, sdl.RENDERER_ACCELERATED)
    assert(renderer != nil, sdl.GetErrorString());

    event : sdl.Event


    start : f32
    end : f32
        
    loopmode : for
    {
        start = cast(f32)sdl.GetTicks() / 1000.0
        
        start_time : u64
        end_time : u64

        dt := get_timestep(1.0 / 62.0)

        if dt > 0.075
        {
            dt = 0.075;
        }

        if(sdl.PollEvent(&event)) {
            if(event.type == sdl.EventType.QUIT) {
                break loopmode
            }

            if(event.type == sdl.EventType.KEYDOWN) {
                if(event.key.keysym.scancode == .ESCAPE) {
                    break loopmode
                }    
            }
        }
        
        sdl.RenderClear(renderer)
        sdl.SetRenderDrawColor(renderer, 25, 110, 110, 100)
        sdl.RenderPresent(renderer)
        end = cast(f32)sdl.GetTicks() / 1000.0
        fmt.println("dt : ", 1.0 / (end - start))

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

    for
    {
        this_time = (cast(f32)sdl.GetTicks() / 1000.0)
        delta_time = cast(f32)(this_time - last_time)
        if delta_time >= minimum_time
        {
            last_time = this_time
            return delta_time
        }
    }

    return 0
}
