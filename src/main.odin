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
    
    loopmode : for
    {
        if(sdl.PollEvent(&event))
        {
            if(event.type == sdl.EventType.QUIT)
            {
                break loopmode
            }

            if(event.type == sdl.EventType.KEYDOWN)
            {
                if(event.key.keysym.scancode == .ESCAPE)
                {
                    break loopmode
                }    
            }
        }
    }
}

