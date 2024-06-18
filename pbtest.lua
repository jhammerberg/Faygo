local box = require("PixelBox").new(term.current())

local function make_background(x,y)
    local dist = math.ceil((x^2 + y^2)^(1/3))%15
    return 2^dist
end

local w,h = term.getSize()

for x=1,w*2 do
    for y=1,h*3 do
        box.CANVAS[y][x] = make_background(x,y)
    end
end

box:render()