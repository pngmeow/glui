//=====================
//  GLUI by pngmeow
//=====================
local lje = lje or {}

local internal = lje.include("library/internal.lua")
local flags = lje.include("library/flags.lua")
style = internal.style

local glui = {}
glui.draw = {}

function glui.beginInput()
    return internal.input.update()
end

function glui.pushStyle(parentTable, key, newValue)
    return internal.pushStyle(parentTable, key, newValue)
end

function glui.popStyle()
    return internal.popStyle()
end

function glui.style(tbl)
    internal.style = tbl
    style = tbl
end

function glui.draw.beginWindow(id, name, x, y, w, h, flag)
    flag = flag or 0

    local window = internal.beginWindow(id, name, x, y, w, h, flag)

    local wx, wy = window.x, window.y
    
    -- window body
    if not window.state.minimized then
        internal.drawColor(style.window.frame)
        surface.DrawRect(wx, wy, w, h)
    end

    -- title bar
    if not flags.get(flag, flags.window.noTitleBar) then
        internal.drawColor(style.title.frame)
        surface.DrawRect(wx, wy, w, style.other.titleHeight)

        internal.textDrawColor(style.title.text)
        surface.SetFont("Default")
        surface.SetTextPos(wx + 10, wy + 4)
        surface.DrawText(window.name)

        -- minimize button
        if not flags.any(flag, flags.window.noMinimize, flags.window.noTitleBar) then
            surface.SetTextPos(wx + w - 15, wy + 4)
            internal.textDrawColor(style.title.text)
            surface.DrawText(window.state.minimized and "+" or "_")
        end
    end

    if flags.has(flag, flags.window.noTitleBar) then
        internal.pushStyle(style.other, "titleHeight", 0)
    end
    

    -- border
    if not flags.get(flag, flags.window.noBorder) then
        internal.drawColor(style.other.border)
        if window.state.minimized then
            surface.DrawOutlinedRect(wx, wy, w, style.other.titleHeight)
        else
            surface.DrawOutlinedRect(wx, wy, w, h)
        end
    end


    -- hot garbage
    if not window.state.minimized then
        internal.pushClip(
            wx,
            wy + style.other.titleHeight,
            wx + w,
            wy + h
        )
    else
        internal.pushClip(
            wx,
            wy + style.other.titleHeight,
            wx + w,
            wy + style.other.titleHeight
        )
    end

    return window
end

function glui.draw.endWindow()
    internal.popClip()
    internal.popStyle() -- make it so if we dont have the titlebar, set it to 0
    internal.endWindow()
    
end

function glui.draw.label(text, x, y, flag)
    flag = flag or 0

    local win = internal.getCurWindow()

    local sx = win and (win.x + x) or x
    local sy = win and (win.y + y + (style.other.titleHeight)) or y

    if not flags.get(flag, flags.label.disabled) then
        internal.textDrawColor(style.text.normal)
    else
        internal.textDrawColor(style.text.disabled)
    end

    surface.SetFont("Default")
    surface.SetTextPos(sx, sy)
    surface.DrawText(text)
end

function glui.draw.labelWrapped(text, x, y, w, h, flag)
    flag = flag or 0

    local win = internal.getCurWindow()
    local lines = internal.textExplode(text, w, h)

    local sx = win and (win.x + x) or x
    local sy = win and (win.y + y + style.other.titleHeight) or y


    surface.SetFont("Default")

    if flags.get(flag, flags.label.debugarea) then
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawRect(sx, sy, w, h)
        surface.SetTextColor(0, 0, 0, 255)
    else
        internal.textDrawColor(style.text.normal)
    end

    local lineHeight = 10
    local padding = 0

    -- Calculate max line width
    local maxLineWidth = 0
    for _, line in ipairs(lines) do
        local lineWidth = surface.GetTextSize(line)
        if lineWidth > maxLineWidth then
            maxLineWidth = lineWidth
        end
    end

    -- hot garbage
    internal.pushClip(
        sx,
        sy,
        sx + w,
        sy + h
    )

    -- Draw text lines
    for i, v in ipairs(lines) do
        surface.SetTextPos(sx + padding, sy + padding + lineHeight * (i - 1))
        surface.DrawText(v)
    end

    -- Disable scissor after drawing
    internal.popClip()
    return #lines * lineHeight + padding * 2
end


function glui.draw.checkbox(id, text, x, y, flag, helper)
    flag = flag or 0
    helper = helper or ""

    local win = internal.getCurWindow()
    local sx = win and (win.x + x) or x
    local sy = win and (win.y + y + style.other.titleHeight) or y

    local checkbox = internal.checkbox(id, text, helper, sx, sy)

    surface.DrawOutlinedRect(sx, sy, 15, 15)

    if checkbox.checked then
        internal.textDrawColor(style.text.normal)
        surface.SetFont("Default")
        surface.SetTextPos(sx + 5, sy + 3)
        surface.DrawText("*")
    end

    if flags.has(flag, flags.checkbox.helper) and helper then
        internal.textDrawColor(style.text.disabled)
        surface.SetFont("Default")
        surface.SetTextPos(sx + surface.GetTextSize(text) + 25, sy + 1)
        surface.DrawText("[?]")
    end

    internal.textDrawColor(style.text.normal)
    surface.SetTextPos(sx + 20, sy + 1)
    surface.DrawText(text)

    return checkbox.checked
end

function glui.draw.button(id, text, x, y, w, h) 
    local win = internal.getCurWindow()
    local sx = win and (win.x + x) or x
    local sy = win and (win.y + y + style.other.titleHeight) or y

    local button = internal.button(id, sx, sy, w, h)

    local frameColor = style.button.frame
    if button.lmb or button.rmb then
        frameColor = style.button.press
    end

    internal.drawColor(frameColor)
    surface.DrawRect(sx, sy, w, h)
    internal.textDrawColor(style.button.text)
    surface.SetFont("Default")
    surface.SetTextPos(sx + (w - select(1, surface.GetTextSize(text))) / 2, sy + (h - select(2, surface.GetTextSize(text))) / 2)
    surface.DrawText(text)

    internal.drawColor(style.other.border)
    surface.DrawOutlinedRect(sx, sy, w, h)


    return button.lmb, button.rmb
end


function glui.draw.slider(id, x, y, w, h, minv, maxv, value)
    minv = minv or 0
    maxv = maxv or 1

    local win = internal.getCurWindow()
    local sx = win and (win.x + x) or x
    local sy = win and (win.y + y + style.other.titleHeight) or y

    local slider, kx, ky, kw, kh = internal.slider(id, sx, sy, w, h, minv, maxv, value)

    -- track
    internal.drawColor(style.button.frame)
    surface.DrawRect(sx, sy + (h/2) - 2, w, 4)

    -- filled portion
    local frac = (slider.value - minv) / (maxv - minv)
    if frac < 0 then frac = 0 end
    if frac > 1 then frac = 1 end
    internal.drawColor(style.button.hover)
    surface.DrawRect(sx, sy + (h/2) - 2, frac * w, 4)

    -- knob
    internal.drawColor(style.button.frame)
    surface.DrawRect(kx, ky, kw, kh)
    internal.drawColor(style.other.border)
    surface.DrawOutlinedRect(kx, ky, kw, kh)

    return slider.value
end



return glui