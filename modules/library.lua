// internal stuff is marked with __

local glui = {}
glui.input = {}
glui.input.mx = 0
glui.input.my = 0
glui.input.lmb = false 
glui.input.rmb = false

// style table
glui.style = {} 

// drawing functions table
glui.draw = {}

// element storage table
glui.elements = {}

// stack table for window stack
glui.stack = {
    windows = {}
}

// implementation of color
local function __color(r, g, b, a)
    return {r,g,b,a}
end

// sets the draw color to __color because generally you have to unpack __color before you can use it
// which is kinda annoying but whateverrrr :)
local function __setDrawColor(c)
    surface.SetDrawColor(unpack(c))
end

local function __setTextDrawColor(c)
    surface.SetTextColor(unpack(c))
end

// returns the current window
local function __currentWindow()
    return glui.stack.windows[#glui.stack.windows]
end

// __isInRect allows us to check if a point is inside a rectangle
local function __isInRect(x, y, w, h, mx, my)
    return mx >= x 
    and mx <= x + w 
    and my >= y 
    and my <= y + h
end

-- word wrap text
local function __wrapText(text, font, maxWidth)
    if not text or text == "" then
        return {}
    end

    text = tostring(text)
    surface.SetFont(font)

    local words = {}
    for word in text:gmatch("%S+") do
        table.insert(words, word)
    end
    local lines = {}
    local currentLine = ""

    for idx = 1, #words do
        local word = words[idx]
        if word ~= nil and word ~= "" then
            surface.SetFont(font)
            local wordWidth = surface.GetTextSize(word)

            -- Inline word splitting for long words
            if wordWidth > maxWidth then
                local chunk = ""
                for i = 1, #word do
                    local testChunk = chunk .. word:sub(i,i)
                    local chunkWidth = surface.GetTextSize(testChunk)

                    if chunkWidth <= maxWidth then
                        chunk = testChunk
                    else
                        if currentLine ~= "" then
                            table.insert(lines, currentLine)
                            currentLine = ""
                        end
                        if chunk ~= "" then
                            table.insert(lines, chunk)
                        end
                        chunk = word:sub(i,i)
                    end
                end

                if chunk ~= "" then
                    if currentLine ~= "" then
                        table.insert(lines, currentLine)
                    end
                    currentLine = chunk
                end
            else
                local testLine = (currentLine == "") and word or (currentLine .. " " .. word)
                local w = surface.GetTextSize(testLine)

                if w <= maxWidth then
                    currentLine = testLine
                else
                    if currentLine ~= "" then
                        table.insert(lines, currentLine)
                    end
                    currentLine = word
                end
            end
        end
    end

    if currentLine ~= "" then
        table.insert(lines, currentLine)
    end

    local function trim(s)
        return s:match("^%s*(.-)%s*$")
    end

    for i, line in ipairs(lines) do
        lines[i] = trim(line)
    end

    return lines
end

__fonts = {}
__fontData = {}
// creates a font, returns the name. If it exists, it returns the cached name.
local function __font(name, data)
    local cached = __fonts[name]
    if cached then return cached end
    
    local id = lje.util.random_string()
    surface.CreateFont(id, data)
    __fonts[name] = id
    __fontData[name] = data

    return id
end

glui.style = {
    __viewport = __color(5, 5, 5, 255),

    other = {
        fonts = {
            default = __font("glui_default", {
                font = "ProggyCleanTT",
                size = 14,
                weight = 500,
                antialias = true,
            }),
        }
    },

    text = {
        normal = __color(220, 220, 220, 255),
        disabled = __color(120, 120, 120, 255),
    },
    
    window = {
        frame = __color(38, 38, 38, 240),
    },

    border = {
        frame = __color(110, 110, 128, 128),
    },
    
    title = {
        frame = __color(41, 74, 122, 255),
        frame_active = __color(61, 94, 142, 255),
        frame_hover = __color(51, 84, 132, 255),
    },
}

function glui.input.run()
    glui.input.mx, glui.input.my = input.GetCursorPos()
    glui.input.lmb = input.IsMouseDown(MOUSE_LEFT)
    glui.input.rmb = input.IsMouseDown(MOUSE_RIGHT)

    return {glui.input}
end

// This draws over the entire screen so its easier to design stuff
// probably not that useful to anyone
function glui.draw.viewport()
    __setDrawColor(glui.style.__viewport)
    surface.DrawRect(0, 0, ScrW(), ScrH())
end

// begin window
function glui.draw.beginWindow(_id, name, x, y, width, height, flagTable)
    if glui.elements[_id] == nil then
        glui.elements[_id] = {
            _id = _id,
            name = name,
            x = x,
            y = y,
            width = width,
            height = height,

            dragging = false,
            drag_x = 0,
            drag_y = 0,

            flagTable = flagTable,
            __internal = {
                minimized = false
            }
        }
    end

    local window = glui.elements[_id]
    // fixed titlebar height, if flagTable.noTitleBar is set, it becomes 0!!!!
    local titleBarHeight = 24 

    // Should we be able to move the window?
    // this is fucked at this moment because of how we are handling titlebar
    if not flagTable.noMove then
        if glui.input.lmb then
            if not window.dragging and __isInRect(window.x, window.y, window.width, titleBarHeight, glui.input.mx, glui.input.my) then
                window.dragging = true
                window.drag_x = glui.input.mx - window.x
                window.drag_y = glui.input.my - window.y
            end
        else
            window.dragging = false
        end

        if window.dragging then
            window.x = glui.input.mx - window.drag_x
            window.y = glui.input.my - window.drag_y
        end
    end

    __setDrawColor(glui.style.window.frame)
    if (not window.__internal.minimized) then
        window.height = height
    else
        window.height = titleBarHeight
    end
    surface.DrawRect(window.x, window.y, window.width, window.height)

    // Should we draw the title bar?
    if not flagTable.noTitleBar then
        titleBarHeight = titleBarHeight

        if window.dragging then
            __setDrawColor(glui.style.title.frame_active)
        else
             __setDrawColor(glui.style.title.frame_hover)
        end

        surface.DrawRect(window.x, window.y, window.width, titleBarHeight)
        surface.SetFont(glui.style.other.fonts.default)
        __setTextDrawColor(glui.style.text.normal)
        surface.SetTextPos(window.x + 6, window.y + 6)
        surface.DrawText(name)

        // Should we draw the minimize button?
        if not flagTable.noMinimize then
            surface.SetTextPos(window.x + window.width - 20 , window.y + 6)
            surface.DrawText("_")
            if __isInRect(
                window.x + window.width - 20, 
                window.y,  -- y position of button
                titleBarHeight, 
                titleBarHeight, 
                glui.input.mx, 
                glui.input.my
            ) and glui.input.lmb then
                window.__internal.minimized = not window.__internal.minimized
            end
        end
    else
        titleBarHeight = 0
    end

    // Should we draw the border?
    if not flagTable.noBorder then
        __setDrawColor(glui.style.border.frame)
        surface.DrawOutlinedRect(window.x, window.y, window.width, window.height, 1)
    end

    // set scissor rect to window area.
    render.SetScissorRect(
        window.x,
        window.y + titleBarHeight,
        window.x + window.width,
        window.y + window.height,
        true
    )

    // push it to the window stack!
    table.insert(glui.stack.windows, {
        x = window.x,
        y = window.y,
        width = window.width,
        height = window.height, 
        titleBarHeight = titleBarHeight,
    })

    return glui.elements[_id]
end

// end window 
// YOU MUST CALL THIS WHEN YOU BEGIN A WINDOW!!
function glui.draw.endWindow()
    // goodbye window from window stack :(
    render.SetScissorRect(0, 0, 0, 0, false)
    table.remove(glui.stack.windows)
end

// Draws a label at X, Y relative to the current window
function glui.draw.label(text, x, y)
    if text == nil then return end

    local parent = __currentWindow()

    if parent then
        x = parent.x + x
        y = parent.y + y + parent.titleBarHeight
    end

    surface.SetFont(glui.style.other.fonts.default)
    __setTextDrawColor(glui.style.text.normal)
    surface.SetTextPos(x, y)
    surface.DrawText(text)
end

function glui.draw.labelWrapped(text, x, y, maxWidth, lineSpacing)
    local parent = __currentWindow()
    local font = glui.style.other.fonts.default
    lineSpacing = lineSpacing or 2

    if not maxWidth then
        if parent then
            maxWidth = parent.width - x
        else
            maxWidth = ScrW() - x
        end
    end

    if parent then
        x = parent.x + x
        y = parent.y + y + parent.titleBarHeight
    end

    surface.SetFont(font)
    __setTextDrawColor(glui.style.text.normal)

    local lines = __wrapText(text, font, maxWidth)
    local _, lineHeight = surface.GetTextSize("Ay")

    for i = 1, #lines do
        surface.SetTextPos(x, y + (i - 1) * (lineHeight + lineSpacing))
        surface.DrawText(lines[i])
    end

    -- return the total height for layout purposes
    return #lines * (lineHeight + lineSpacing)
end


return glui
