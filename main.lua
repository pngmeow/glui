lje = lje or {}

if lje == nil then print("Can't find LJE, bailing out!") return end

lje.con_print("load: glui and example")
local example = lje.include("library/example.lua")

lje.con_print("load complete!")