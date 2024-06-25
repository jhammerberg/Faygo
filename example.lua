local faygo = require("Faygo")
local gui = faygo.newGUI() -- Initialize the GUI, no monitor arguments defaults to the terminal

-- If we wanted to, we can do another init with a different object and attach it to a monitor and address it at the same time
-- Like this:
local monitor_peripheral = peripheral.find("monitor")
if monitor_peripheral ~= nil then
    Mon = faygo.newGUI(monitor_peripheral) 
    Mon:setBackground(colors.black)
    Mon:clr()
end

gui:setBackground(colors.black)
gui:clr()

gui:newButton(colors.blue, colors.green, {x = 2, y = 2}, {x = (gui.absWidth-2), y = (gui.absHeight-2)}, "Press this button!", function(thisButton)
    thisButton:redraw(colors.black, colors.red, "Pressed!")
    os.sleep(1) -- Not entirely ideal because it blocks the event listener loop, effectively freezing the GUI. Main thread will still run.
    thisButton:redraw()
end)

local function main()
    while true do
        -- Imagine this has other program logic
        os.sleep(1)
    end
end

faygo.run(main)