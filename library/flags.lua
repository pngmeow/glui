flags = {}

// Window flags
flags.window = {
    noTitleBar = bit.lshift(1,0), -- 1
    noBorder   = bit.lshift(1,1), -- 2
    noMove     = bit.lshift(1,2), -- 4
    noResize   = bit.lshift(1,3), -- 8
    noMinimize = bit.lshift(1,4), -- 16
}

flags.label = {
    disabled = bit.lshift(1,0), -- 1
    debugarea = bit.lshift(1,1), -- 2 [draws a white box behind text, draws text black. Used for testing labelWrapped.]
}

flags.checkbox = {
    helper = bit.lshift(1,0) -- 1 [draws a helper text]
}

// Compiles given flags into a number
function flags.compile(...)
    local out = 0

    for i = 1, select("#", ...) do
        local v = select(i, ...)
        if v ~= nil then
            out = bit.bor(out, v)
        end
    end

    return out
end

// Checks if any given flags 
function flags.any(mask, ...)
    local combined = flags.compile(...)
    return bit.band(mask, combined) ~= 0
end


// Returns flags from number
function flags.get(mask, flag)
    return bit.band(mask, flag) ~= 0
end

// Alias
flags.has = flags.get 

return flags