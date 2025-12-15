local glui = lje.include("modules/library.lua")

-- draw to safe rendertarget (thanks Eyoko1!)
hook.pre("DrawRT", "__example_renderer", function()
    render.PushRenderTarget(lje.util.rendertarget)
    
    glui.input.run() 
    //glui.draw.viewport()
    glui.draw.beginWindow(
        "example_window_overlay", 
        10, 
        10, 
        200, 
        40, 
        {
            noTitleBar = true, 
            noBorder = false, 
            noMove = true
        }
    )

    //10, 13
    glui.draw.label(game.GetIPAddress(), 10, 13 )
    
    glui.draw.endWindow()

    glui.draw.beginWindow("Example Window!", 200, 200, 400, 400, {noTitleBar = false, noBorder = false, noMove = false})
    glui.draw.endWindow()


    render.PopRenderTarget()
end)
