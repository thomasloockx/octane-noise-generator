-- Generates different shaders based on Perlin noise in Octane.
--
-- @description Generates various materials based on perlin noise.
-- @author      Thomas Loockx
-- @version     0.1
-- @copyright   (c) Thomas Loockx - 2014

require "noise-generator/materials"

-- Create the tabbed component based on the materials
local gui = materials.gui()

local window = octane.gui.create
{
    type     = octane.gui.componentType.WINDOW,
    width    = gui.width,
    height   = gui.height,
    children = { gui },
    text     = "Procedural Texture Generator",
}

window:showWindow()
