local glui = lje.include("library/library.lua")
local flags = lje.include("library/flags.lua")
// >> THEMES
// >> Uncomment any of those themes to use them. 
// >> You can also create your own theme by modifying the table.
// >> Make sure to use glui.style(style) in your rendering code, or the style wont take effect, and glui will use the default style.

-- >> eyoko1 theme (imgui)

local style = {
    other = {
        titleHeight = 20,
        border = col(110, 110, 128, 128),
        helpText = col(255,255,255,255)

    },

    text = {
        normal = col(255, 255, 255, 255),
        disabled = col(128, 128, 128, 255)
    },

    button = {
        frame = col(41, 74, 122, 255),
        hover = col(61, 94, 142, 255),
        press = col(51, 84, 132, 255),
        text = col(255, 255, 255, 255)
    },

    title = {
        frame = col(41, 74, 122, 255),
        hover = col(61, 94, 142, 255),
        press = col(51, 84, 132, 255),
        text = col(255, 255, 255, 255)
    },

    window = {
        frame = col(38, 38, 38, 240)
    }
}



-- >> aimware theme
--[[
local style = {
    other = {
        titleHeight = 20,
        border = col(110, 110, 128, 128),
        helpText = col(255,0,0,255)
    },

    text = {
        normal = col(0, 0, 0, 255),
        disabled = col(128, 128, 128, 255)
    },

    button = {
        frame = col(143, 1, 20, 255),
        hover = col(180, 20, 40, 255),
        press = col(220, 40, 60, 255),
        text = col(255, 245, 240, 255)
    },
    
    tab = {
        frame = col(0, 0, 0, 0),
        btn_frame = col(143, 1, 20, 255),
        hover = col(180, 20, 40, 255),
        press = col(220, 40, 60, 255),
        text = col(255, 245, 240, 255)
    },

    title = {
        frame = col(143, 1, 20, 255),
        hover = col(180, 20, 40, 255),
        press = col(220, 40, 60, 255),
        text = col(255, 245, 240, 255)
    },

    window = {
        frame = col(255, 255, 255, 255)
    }
}
]]

hook.pre("ljeutil/render", "example", function()
    local mx, my = glui.beginInput()


    local i = 0


    cam.Start2D()
    
    render.PushRenderTarget(lje.util.rendertarget)

    glui.style(style)
    glui.draw.beginWindow("overlayWindow", "overlay window test!", 10, 10, 200, 30, flags.compile(flags.window.noTitleBar, flags.window.noMove))
        glui.draw.label("5cent utility mod", 10, 8)
    glui.draw.endWindow()

    
    glui.draw.beginWindow("utilityListWindow", "util list", 10, 50, 200, 360, flags.compile(flags.window.noMinimize))

    glui.draw.endWindow()


    
    glui.draw.beginWindow("mainWindow","main ", 215, 10, 400, 400)
        glui.draw.label("Example label", 10, 10)
        glui.draw.checkbox("exampleCheckbox2", "Checkbox", 10, 30)
        glui.draw.checkbox("exampleCheckbox3", "Checkbox question", 10, 50, flags.compile(flags.checkbox.helper), "help")
        glui.draw.button("exampleButton1", "button", 10, 80, 100, 30)
        local val = glui.draw.slider("volume", 10, 120, 200, 16, 0, 100)

        glui.draw.label("Value: "..math.floor(val), 10, 160)

    glui.draw.endWindow()

   

    surface.SetDrawColor(80, 80, 255, 255)
    surface.DrawRect(mx, my, 5, 5)
    render.PopRenderTarget()
    cam.End2D()

end)

