local flags = lje.include("library/flags.lua")
local internal = internal or {}

internal.stack = {}
internal.stack.clip =  {}
internal.stack.style = {}


// keep both current scissor, and window.
internal.curClip = nil
internal.curWindow = internal.curWindow or nil


//=====================
//  UTILS
//=====================

local function intersect(a, b)
    if not a then return b end
    if not b then return a end

    local x1 = math.max(a[1], b[1])
    local y1 = math.max(a[2], b[2])
    local x2 = math.min(a[3], b[3])
    local y2 = math.min(a[4], b[4])

    if x2 <= x1 or y2 <= y1 then
        return {0, 0, 0, 0}
    end

    return {x1, y1, x2, y2}
end

local function isInRect(x, y, w, h, mx, my)
    return mx >= x 
    and mx <= x + w 
    and my >= y 
    and my <= y + h
end

function internal.color(r, g, b, a)
    return {r, g, b, a}
end

col = internal.color

function internal.drawColor(color)
    surface.SetDrawColor(unpack(color))
end

function internal.textDrawColor(color)
    surface.SetTextColor(unpack(color))
end

function internal.textExplode(text, w, h)
    local final = ""
    local t = {}
    local lines = {}

    local lineHeight = 10 

    string.gsub(text, ".", function(c)
        table.insert(t, c)
    end)

    for i, v in ipairs(t) do
        local testLine = final .. v
        local width = surface.GetTextSize(testLine)
        if width > w then
            if (#lines + 1) * lineHeight > h then
                break
            end
            table.insert(lines, final)
            final = v
        else
            final = testLine
        end
    end

    if final ~= "" and (#lines + 1) * lineHeight <= h then
        table.insert(lines, final)
    end

    return lines
end

//=====================
//  STACK
//=====================
function internal.pushStyle(parentTable, key, newValue)
    -- Save current value
    table.insert(internal.stack.style, { parentTable, key, parentTable[key] })
    
    -- Set new value
    parentTable[key] = newValue
end

function internal.popStyle()
    local entry = table.remove(internal.stack.style)
    if not entry then return end
    
    local parentTable, key, oldValue = entry[1], entry[2], entry[3]
    parentTable[key] = oldValue
end

function internal.pushClip(x1, y1, x2, y2)
    table.insert(internal.stack.clip, internal.curClip)

    local newClip = { x1, y1, x2, y2 }
    internal.curClip = intersect(internal.curClip, newClip)

    if internal.curClip then
        render.SetScissorRect(
            internal.curClip[1],
            internal.curClip[2],
            internal.curClip[3],
            internal.curClip[4],
            true
        )
    else
        render.SetScissorRect(0, 0, 0, 0, false)
    end
end


function internal.popClip()
    internal.curClip = table.remove(internal.stack.clip)

    if internal.curClip then
        render.SetScissorRect(
            internal.curClip[1],
            internal.curClip[2],
            internal.curClip[3],
            internal.curClip[4],
            true
        )
    else
        render.SetScissorRect(0, 0, 0, 0, false)
    end
end

function internal.getCurWindow()
    return internal.curWindow
end

//=====================
//  STYLE
//=====================
internal.style = {
    other = {
        titleHeight = 20,
        border = col(80, 80, 80, 255),
        helpText = col(255,255,255,255)

    },

    text = {
        normal = col(255, 255, 255, 255),
        disabled = col(128, 128, 128, 255)
    },

    button = {
        frame = col(35, 35, 35, 255),
        hover = col(50, 50, 50, 255),
        press = col(80, 80, 80, 255),
        text = col(255, 255, 255, 255)
    },

    tab = {
        frame = col(35, 35, 35, 255),
        hover = col(50, 50, 50, 255),
        press = col(80, 80, 80, 255),
        btn_frame = col(143, 1, 20, 255),
        text = col(255, 255, 255, 255)
    },

    title = {
        frame = col(35, 35, 35, 255),
        hover = col(50, 50, 50, 255),
        press = col(80, 80, 80, 255),
        text = col(255, 255, 255, 255)
    },

    window = {
        frame = col(45, 45, 45, 255)
    }
}


//=====================
//  INPUT
//=====================
internal.input = {
    x = 0,
    y = 0,
    lmb = {pressed = false, released = false, down = false},
    rmb = {pressed = false, released = false, down = false},
}


local function updateButton(btn, key)
    local isDown = input.IsMouseDown(key)

    btn.pressed = isDown and not btn.down 
    btn.released = not isDown and btn.down 
    btn.down = isDown
end


function internal.input.update()
    internal.input.x, internal.input.y = input.GetCursorPos()

    updateButton(internal.input.lmb, MOUSE_LEFT)
    updateButton(internal.input.rmb, MOUSE_RIGHT)

    return internal.input.x, internal.input.y
end


//=====================
//  LOGIC
//=====================

function internal.beginWindow(id, name, x, y, w, h, flag)
    local window = internal.stack[id]

    if not window then
        window = {
            name = name,
            x = x,
            y = y,
            w = w,
            h = h,
            numFlag = flag or 0,
            state = {
                dragging = false,
                drag_x = 0,
                drag_y = 0,
                minimized = false,
                isOpen = true
            } 
        }
        internal.stack[id] = window
    end
    
    internal.curWindow = window


    if not flags.has(flag, flags.window.noMove) then
        local mx, my = internal.input.x, internal.input.y
        local titleH = internal.style.other.titleHeight

        -- mouse is over title bar
        local hoverTitle = isInRect(
            window.x,
            window.y,
            window.w,
            titleH,
            mx,
            my
        )

        if hoverTitle then
            internal.pushStyle(internal.style.title, "frame", internal.style.title.hover)
        else
            internal.popStyle()
        end

        -- start dragging
        if hoverTitle and internal.input.lmb.pressed then
            window.state.dragging = true
            window.state.drag_x = mx - window.x
            window.state.drag_y = my - window.y
        end

        -- drag update
        if window.state.dragging then
            internal.pushStyle(internal.style.title, "frame", internal.style.title.press)
            if internal.input.lmb.down then
                window.x = mx - window.state.drag_x
                window.y = my - window.state.drag_y
            else
                -- stop dragging
                window.state.dragging = false
                internal.popStyle()
            end
        end
    end

    if not flags.any(flag, flags.window.noMinimize, flags.window.noTitleBar) then
        local mx, my = internal.input.x, internal.input.y
        local titleH = internal.style.other.titleHeight


        local hoverMinimize = isInRect(
            window.x + window.w - 20,
            window.y + 4,
            16,
            titleH - 8,
            mx,
            my
        )

        if hoverMinimize and internal.input.lmb.pressed then
            window.state.minimized = !window.state.minimized

            if window.state.minimized then
                window.h = internal.style.other.titleHeight
            else
                window.h = h 
            end
        end
    end

    return window
end

function internal.endWindow()
    internal.curWindow = nil
end

function internal.checkbox(id, text, helper, x, y)
    local mx, my = internal.input.x, internal.input.y
    local checkbox = internal.stack[id]

    if not checkbox then
        checkbox = {
            checked = false
        }
        internal.stack[id] = checkbox
    end

    local hover = isInRect(x, y, 15, 15, mx, my)
    local hover_tooltip = isInRect(x + surface.GetTextSize(text) + 25, y + 1, 15, 15, mx, my)

    if hover and internal.input.lmb.pressed then
        checkbox.checked = !checkbox.checked
    end

    if hover_tooltip then
        internal.textDrawColor(internal.style.other.helpText)
        surface.SetFont("Default")
        surface.SetTextPos(mx, my + 20)
        surface.DrawText(helper)
    end


    return checkbox
end

function internal.button(id, x, y, w, h)
    local mx, my = internal.input.x, internal.input.y
    local button = internal.stack[id]

    if not button then
        button = {
            lmb = false,
            rmb = false,
        }
        internal.stack[id] = button
    end

    local hover = isInRect(x, y, w, h, mx, my)

    -- set click states when hovered
    button.lmb = hover and internal.input.lmb.pressed
    button.rmb = hover and internal.input.rmb.pressed

    
    return button
end


function internal.slider(id, x, y, w, h, minv, maxv, value)
    local mx, my = internal.input.x, internal.input.y
    local slider = internal.stack[id]

    if not slider then
        slider = {
            value = value or (minv or 0),
            dragging = false,
        }
        internal.stack[id] = slider
    end

    -- allow caller to initialize/override value
    if value ~= nil then
        slider.value = value
    end

    minv = minv or 0
    maxv = maxv or 1
    if maxv == minv then maxv = minv + 1 end

    -- compute fraction and knob geometry
    local frac = (slider.value - minv) / (maxv - minv)
    if frac < 0 then frac = 0 end
    if frac > 1 then frac = 1 end

    local knobW = math.min(8, w)
    local knobH = h
    local knobX = x + frac * (w - knobW)
    local knobY = y

    local hoverKnob = isInRect(knobX, knobY, knobW, knobH, mx, my)
    local hoverTrack = isInRect(x, y, w, h, mx, my)

    -- start dragging when pressing on knob
    if hoverKnob and internal.input.lmb.pressed then
        slider.dragging = true
    end

    -- click on track jumps the knob
    if hoverTrack and internal.input.lmb.pressed then
        local localx = mx - x
        local newFrac = localx / w
        if newFrac < 0 then newFrac = 0 end
        if newFrac > 1 then newFrac = 1 end
        slider.value = minv + newFrac * (maxv - minv)
    end

    -- dragging updates value continuously
    if slider.dragging then
        if internal.input.lmb.down then
            local localx = mx - x
            if localx < 0 then localx = 0 end
            if localx > w then localx = w end
            local newFrac = localx / w
            slider.value = minv + newFrac * (maxv - minv)
        else
            slider.dragging = false
        end
    end

    -- clamp
    if slider.value < minv then slider.value = minv end
    if slider.value > maxv then slider.value = maxv end

    return slider, knobX, knobY, knobW, knobH, frac
end


return internal