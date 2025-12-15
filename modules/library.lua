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

function glui.draw.viewport()
    __setDrawColor(glui.style.__viewport)
    surface.DrawRect(0, 0, ScrW(), ScrH())
end

// begin window
function glui.draw.beginWindow(name, x, y, width, height, flagTable)
    if glui.elements[name] == nil then
        glui.elements[name] = {
            name = name,
            x = x,
            y = y,
            width = width,
            height = height,

            dragging = false,
            drag_x = 0,
            drag_y = 0,

            flagTable = flagTable
        }
    end

    local window = glui.elements[name]
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



return glui
