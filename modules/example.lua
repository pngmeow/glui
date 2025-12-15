local glui = lje.include("modules/library.lua")

-- draw to safe rendertarget (thanks Eyoko1!)
hook.pre("DrawRT", "__example_renderer", function()
    render.PushRenderTarget(lje.util.rendertarget)
    
    glui.input.run() 
    //glui.draw.viewport()
    glui.draw.beginWindow("example_overlay", "example_window_overlay", 10, 10, 200, 40, {noTitleBar = true, noBorder = false, noMove = true})

    glui.draw.label(game.GetIPAddress(), 10, 13 )
    
    glui.draw.endWindow()

    local x = glui.draw.beginWindow("example_main", "Example Window!", 200, 200, 500, 400, {noTitleBar = false, noBorder = false, noMove = false})
        glui.draw.label("hello, i'm clippy! Clippy loves cliping.", -5, 13 )
        glui.draw.label("hello, i'm clippy's junior! But i don't feel like clipping.", 5, 32, 280)
        glui.draw.labelWrapped("hello, i'm clippy's junior cousin! But my name is wrapping! Here's my special attack: ", 5, 62)
        local specialChars = ""

        for i = 1, 126 do
            local c = string.char(i)
            specialChars = specialChars .. c
        end

        glui.draw.labelWrapped(specialChars, 5, 80, 200)

    glui.draw.endWindow()

    print(x.__internal.minimized)

    render.PopRenderTarget()
end)
