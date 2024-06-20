# Faygo API
The Faygo API is a multipurpose and universal GUI API for ComputerCraft.

The goal of Faygo is to provide an easy way to draw elements and create buttons on any screen or terminal with the same code, regardless of the screen's size or type. 

## Features

- Create different GUIs for attached terminals and monitors
- Draw rectangles, lines, cirlces, and text on any screen
- Create buttons with custom callback functions
- Automatically scale elements to fit any screen size
- Use the same code for any screen or terminal
- A custom event listener for button presses
- A single lua file that does only relies on the ComputerCraft API

## Usage

### Download the Faygo.lua to your computer with
### `wget https://raw.githubusercontent.com/jhammerberg/Faygo/main/Faygo.lua`

### Load the Faygo API with
```lua
local faygo = require("Faygo")
```

### Create a new terminal GUI with
```lua
local gui = faygo.initGUI()
```

### Or create a new monitor GUI with
```lua
local mon = faygo.initGUI([monitor])
```

### Draw a button with
```lua
local button = gui:newButton([color], [startX], [startY], [endX], [endY], [callback_function])
```
*make sure you exclude parentheses for the callback function*

### Start Faygo with
```lua
faygo.run([main])
```
**Where main is the name of your program's main looping function, do not include parentheses**\
*Alternatively, you can also call `faygo.run()` without a function, which will start a blocking event loop*\
*Or even call `faygo.checkEvents()` inside of your main program loop, but this is not reccomended as this will block the loop, and could cause input lag depending on how long it takes for your loop to run*

### Draw a rectangle with
```lua
gui:drawRect([color], [startX], [startY], [endX], [endY])
```

### Kill a button with
```lua
gui:killButton([button])
```

### Kill a GUI with
```lua
gui:killGUI()
```

### Clean up all screens and exit with
```lua
faygo.cleanUp()
```

**Look at the source code for all functions, their parameters and aliases.**

## Examples

### Drawing some shapes
```lua
local faygo = require("Faygo")
local gui = faygo.initGUI() -- Initialize the GUI, no monitor arguments defaults to the terminal

gui:drawRect(colors.red, 10, 10, 90, 90) -- Draw a red rectangle
gui:drawLine(colors.blue, 10, 10, 90, 90) -- Draw a blue line
gui:drawCircle(colors.green, 50, 50, 40) -- Draw a green circle

-- faygo.run() is not needed since this example does not use buttons or animations
```

### Simple Button
```lua
local faygo = require("Faygo")
local gui = faygo.initGUI()
gui:setBackground(colors.black)
gui:clr()
gui:newButton(colors.green, 10, 10, 90, 90, "Click me!", function()
    gui:setBackground(colors.green)
    gui:drawTextCenter(colors.white, 50, 50, "You clicked this button!")
    os.sleep(0.5)
    gui:drawTextCenter(colors.green, 50, 50, "You clicked this button!")
    gui:drawTextCenter(colors.blue, 50, 50, "Click me!")
end)

local function main()
    while true do
        -- Imagine this has other program logic
        os.sleep(1)
    end
end

faygo.run(main) -- This is required for button callbacks to function
faygo.cleanUp() -- Technically optional, but will clean up the screen if the program quits unexpectedly.
```

### See the examples.lua file for some more examples with monitors and multiple buttons

## Q & A

### Why are elements not showing up on my screen/not where I told them to be?
Faygo uses a different coordinate system to ComputerCraft, with **1, 1 being the bottom left** corner and **100, 100 being the top right** corner, regardless of the resolution of the screen it's drawn on. This makes it easier to scale elements to fit any screen size.

### Why are my buttons not working?
Make sure that you have started the event listener, either with `faygo.run()` or `faygo.run(main)` where `main` is the name of your program's main looping function.

### Why are my circles look like squares?
The code used to draw circles breaks down at small radiuses, try using `gui:drawRectRound()` instead.

### Why is it called Faygo?
Because I needed to name the folder something so I looked around my room and saw a bottle of Faygo :)

## License

Feel free to modify and redistribute this code, I don't need any credit as long as you don't claim the original is yours