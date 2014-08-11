-- Generates different shaders based on Perlin noise in Octane.
--
-- @description Generates various materials based on perlin noise.
-- @author      Thomas Loockx
-- @version     0.11 (Tested with OctaneRender 1.55 and 2.04)
-- @copyright   (c) Thomas Loockx - 2014

require "noise-generator/materials"

-- version string
local VERSION = "0.11"

-- Create the tabbed component based on the materials
local gui = materials.gui()

local window = octane.gui.create
{
    type     = octane.gui.componentType.WINDOW,
    width    = gui.width,
    height   = gui.height,
    children = { gui },
    text     = string.format("Noise Generator %s", VERSION)
}

window:showWindow()
