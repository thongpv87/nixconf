hl = {}
setmetatable(hl, {
    __index = function(t, k)
        return function(...) end
    end
})
dofile("/home/thongpv87/.config/hypr/hyprland.lua")
print("SUCCESS")
