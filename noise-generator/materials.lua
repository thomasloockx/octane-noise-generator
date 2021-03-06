------------------------------------------------------------------------------
-- Materials based on Perlin Noise. ADD YOUR OWN MATERIALS IN THIS FILE

require "noise-generator/perlin"
require "noise-generator/table2d"
require "noise-generator/worley"

-- you can set this to a bigger value if you have a fast computer
local PREVIEW_SIZE = 128 
-- if true , we display the noise generation times
local PROFILE = false 

-- Table with an entry for each generated material. When you'd like to add
-- a new material, add a new entry in this table and a new tab is generated.
local MATERIALS_DESCRIPTION =
{
    -- Perlin noise is the first one in this list. It's the "base" for all others
    -- Copy over this one if you want to add your own material.
    {
        -- Name of the generated material, shown in the material tab.
        name = "Perlin Noise",

        -- Control parameters for the materials. For each element of this list,
        -- a label and a slider is generated.
        controls = 
        {
            { name = "x-orig", value = 0 , min = 0    , max = 256 , step = 0.1  , log = false },
            { name = "y-orig", value = 0 , min = 0    , max = 256 , step = 0.1  , log = false },
            { name = "width" , value = 10, min = 0.001, max = 1000, step = 0.001, log = true  },
            { name = "height", value = 10, min = 0.001, max = 1000, step = 0.001, log = true  },
        },

        -- Generate function for the material. The function is expected to generate the material
        -- in the provided table based on the controls (table with the control parameters).
        -- There's an optional progress callback to make the GUI responsive.
        generate = function(t2d, controls, progressCallback)
                        -- get the 2d table's dimensions
                        local w = t2d.width
                        local h = t2d.height
                        -- get the rectangle bounds in "noise space" based on the controls
                        local x0 = controls["x-orig"]
                        local y0 = controls["y-orig"]
                        local dx = controls["width"] / w 
                        local dy = controls["height"] / h

                        -- for each pixel of the bitmap generate the noise
                        for ys=1,h do
                            for xs=1,w do
                                -- convert from screen space -> "noise space"
                                local x = x0 + dx * (xs - 1)
                                local y = y0 + dy * (ys - 1)
                                -- generate the noise
                                local n = perlin.gen2d(x, y) 
                                -- colour the value in grayscale
                                t2d:set(xs, ys, n * 255)
                            end

                            -- update on our current progress after we've finished a row
                            if (progressCallback) then progressCallback(ys / h) end
                        end
                    end,
    }
    ,
    {
        name = "Wood Rings",

        controls = 
        {   
            { name = "x-orig"    , value = 0   , min = 0    , max = 256 , step = 0.1  , log = false },
            { name = "y-orig"    , value = 0   , min = 0    , max = 256 , step = 0.1  , log = false },
            { name = "width"     , value = 10  , min = 0.001, max = 1000, step = 0.001, log = true  },
            { name = "height"    , value = 10  , min = 0.001, max = 1000, step = 0.001, log = true  },
            { name = "smoothness", value = 0.10, min = 0.01 , max = .2  , step = 0.01 , log = false },
            { name = "period"    , value =   13, min =    1 , max = 40  , step = 0.1  , log = false },
        },

        -- Generates wood rings by mangling the Perlin noise through a sine function.
        generate = function(t2d, controls, progressCallback)
                        -- get the 2d table's dimensions
                        local w = t2d.width
                        local h = t2d.height
                         -- get the centre point of the view rectangle
                        local cx = controls["x-orig"] + controls["width"] * 0.5 
                        local cy = controls["y-orig"] + controls["height"] * 0.5
                        -- get the rectangle bounds in "noise space" based on the controls
                        local x0 = controls["x-orig"]
                        local y0 = controls["y-orig"]
                        local dx = controls["width"] / w 
                        local dy = controls["height"] / h

                        -- for each pixel of the bitmap generate the noise
                        for ys=1,h do
                            for xs=1,w do
                                -- convert from screen space -> "noise space"
                                local x = x0 + dx * (xs - 1)
                                local y = y0 + dy * (ys - 1)
                                -- calculate the distance from the centre
                                local d = math.sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy))
                                -- Distort the distance with some perline noise. The smoothness
                                -- determines the influence of ther perlin noise
                                local dd =  controls["smoothness"] * perlin.gen2d(x, y) + d
                                -- Take the sinus based on the distance. The period determines how
                                -- much rings are generated.
                                local n = math.sin(controls["period"] * dd) + 1
                                -- colour the pixel in grayscale
                                t2d:set(xs, ys, n * 255)
                            end

                            -- update on our current progress after we've finished a row
                            if (progressCallback) then progressCallback(ys / h) end
                        end
                    end,
    }
    ,
    {
        name = "Cellular Noise",
        controls = 
        {
            { name = "width" , value = 20, min = 1, max = 100, step = 0.1, log = true  },
            { name = "height", value = 20, min = 1, max = 100, step = 0.1, log = true  },
        },

        generate = function(t2d, controls, progressCallback)
                        -- get the 2d table's dimensions
                        local w  = t2d.width
                        local h  = t2d.height
                        local dx = controls["width"]  / w
                        local dy = controls["height"] / h

                        -- for each pixel of the bitmap generate the noise
                        for ys=1,h do
                            for xs=1,w do
                                -- convert from screen space -> "noise space"
                                local x      = dx * (xs - 1)
                                local y      = dy * (ys - 1)
                                local F, IDs = worley.gen2d(x, y, 1)
                                local n      = F[1] -- IDs[1]
                                -- colour the pixel in grayscale
                                t2d:set(xs, ys, n * 255)
                            end

                            -- update on our current progress after we've finished a row
                            if (progressCallback) then progressCallback(ys / h) end
                        end
                    end,
    }
    ,
    --
    -- YOUR AWESOME MATERIAL GOES HERE
    --
}


-- this can take several seconds so we report back on our progress
local function createNode(matInfo, controls, w, h, progressBar)
    progressBar.text = "generating noise..."

    -- callback update function
    local updateCount = 0
    local onUpdate = function(progress)
        progressBar.progress = progress
        updateCount          = updateCount + 1
        -- only dispatch so often
        if math.fmod(updateCount, 50) == 0 then
            octane.gui.dispatchGuiEvents(1)
        end
    end

    -- generate the noise output
    local out = table2d.create(w, h)
    matInfo.generate(out, controls, onUpdate)

    -- update progress
    progressBar.text     = "creating texture node..."
    progressBar.progress = -1
    octane.gui.dispatchGuiEvents(1)

    -- TODO: this is inefficient as hell!
    local buf = {} 
    for y=h,1,-1 do
        for x=1,w do
            local noiseValue = out:get(x, y)
            table.insert(buf, noiseValue)
        end
    end

    -- create an image texture node
    tex= octane.node.create{ type=octane.NT_TEX_FLOATIMAGE, name=matInfo.name }
    -- set up the attributes
    tex:setAttribute(octane.A_BUFFER, buf                       , false)
    tex:setAttribute(octane.A_SIZE  , { w , h }                 , false)
    tex:setAttribute(octane.A_TYPE  , octane.image.type.LDR_MONO, false)
    tex:evaluate()

    -- reset the progress bar again
    progressBar.progress = 0
    progressBar.text     = "" 
end


------------------------------------------------------------------------------
-- Material control user interface.

-- Generates the user interface based on above materials.
local function genGui()
    -- Gui constants
    local sliderWidth, sliderHeigt = 400, 20
    local lblWidth   , lblHeight   = 80 , 24
    local innerGrpPad              = 4
    local innerGrpInset            = 5 
    local outerGrpInset            = 5 

    local groups   = {} -- groups, 1 for each tab
    local captions = {} -- captions on top of each tab
    for i, info in ipairs(MATERIALS_DESCRIPTION) do
        table.insert(captions, info.name)

        -- bitmap that wraps an image to preview the noise
        info.preview = octane.gui.create
        {
            type   = octane.gui.componentType.BITMAP,
            width  = PREVIEW_SIZE,
            height = PREVIEW_SIZE,
        }
 
        -- for each control parameter of the material, we generate a slider and
        -- a label with a short name for the control parameter
        local childComponents = {}
        for ci , cvals in pairs(info.controls) do
            local lbl = octane.gui.create
            { 
                type   = octane.gui.componentType.LABEL,
                text   = cvals.name,
                width  = lblWidth,
                height = lblHeight,
            }
            local slider = octane.gui.create
            {
                name        = cvals.name,
                type        = octane.gui.componentType.SLIDER,
                width       = sliderWidth,
                height      = sliderHeigt,
                value       = cvals.value,
                minValue    = cvals.min,
                maxValue    = cvals.max,
                step        = cvals.step,
                logarithmic = cvals.log,
            }
            table.insert(childComponents, lbl)
            table.insert(childComponents, slider)
        end

        -- function that gathers all parameter values from the sliders
        local getControls = function()
            local params = {}
            for _, slider in ipairs(childComponents) do
                if slider.type ~= octane.gui.componentType.slider then 
                    params[slider.name] = slider.value
                end
            end
            return params
        end

        -- function to re-generate the noise
        local reGen = function()
            local startTime = os.clock()

            -- create a new (grayscale) image to hold the preview
            local previewImage = octane.image.create
            {
                type = octane.image.type.LDR_MONO,
                size = { PREVIEW_SIZE, PREVIEW_SIZE }
            }

            -- generate the noise and copy it into the bitmap
            local t2d = table2d.create(info.preview.width, info.preview.height)
            info.generate(t2d, getControls()) 
            for x=1,t2d.width do
                for y=1,t2d.height do
                    previewImage:setPixel(x, y, t2d:get(x, y))
                end
            end

            -- update the bitmap image
            info.preview.image = previewImage

            -- print profiling output
            local genTime = os.clock() - startTime
            if (PROFILE) then
                print(string.format("Generated '%s' in %fs (resolution %dx%d)",
                      info.name, genTime, t2d.width, t2d.height))
            end
        end

        -- when sliders change, make sure we re-generate the noise
        for _, comp in pairs(childComponents) do
            if comp.type == octane.gui.componentType.SLIDER then
                comp.callback = reGen
            end
        end
                
        -- make sure we generate the initial noise
        reGen()

        -- Group with the noise control settings.
        local controlsGrp = octane.gui.create 
        {
            type     = octane.gui.componentType.GROUP,
            rows     = #childComponents/2,
            cols     = 2,
            text     = "Noise Controls",
            border   = true,
            children = childComponents,
            inset    = { innerGrpInset },
        }

        -- Create the user interface for node creation.
        local xResLbl = octane.gui.create
        { 
            type   = octane.gui.componentType.LABEL,
            text   = "x-resolution",
            width  = lblWidth,
            height = lblHeight,
        }
        local xResSlider = octane.gui.create
        {
            type     = octane.gui.componentType.SLIDER,
            width    = sliderWidth,
            height   = sliderHeigt,
            value    = 512,
            minValue = 8,
            maxValue = 2048,
            step     = 1,
        }
        local yResLbl = octane.gui.create
        { 
            type   = octane.gui.componentType.LABEL,
            text   = "y-resolution",
            width  = lblWidth,
            height = lblHeight,
        }
        local yResSlider = octane.gui.create
        {
            type     = octane.gui.componentType.SLIDER,
            width    = sliderWidth,
            height   = sliderHeigt,
            value    = 512,
            minValue = 8,
            maxValue = 2048,
            step     = 1,
        }
        local exportProgress = octane.gui.create
        {
            type     = octane.gui.componentType.PROGRESS_BAR,
            width    = PREVIEW_SIZE,
            height   = 20,
        }
        local exportButton = octane.gui.create
        {
            type    = octane.gui.componentType.BUTTON,
            width   = 80,
            height  = 24,
            text    = "Export",
            tooltip = "exports the noise pattern to a float texture node",
            callback = function(button)
                -- disable the export button
                button.enable = false

                createNode(info, getControls(), xResSlider.value, yResSlider.value, exportProgress)

                -- re-enable the export button
                button.enable = true
            end
        }
        local exportGrp = octane.gui.create
        {
            type     = octane.gui.componentType.GROUP,
            rows     = 2,
            cols     = 2,
            border   = true,
            text     = "Texture Resolution",
            children =
            { 
                xResLbl, xResSlider,
                yResLbl, yResSlider,
            },
            inset = { innerGrpInset },
        }
        local leftColGroup = octane.gui.create 
        {
            type     = octane.gui.componentType.GROUP,
            rows     = 3,
            cols     = 1,
            border   = false,
            children =
            { 
                info.preview,
                exportProgress,
                exportButton
            },
            inset   = { 5, 12 },
            padding = { 0, 3, 0, 0},
        }
        local rightColGroup = octane.gui.create 
        {
            type     = octane.gui.componentType.GROUP,
            rows     = 2,
            cols     = 1,
            border   = false,
            children =
            { 
                controlsGrp,
                exportGrp,
            },
            inset = { outerGrpInset },
        }
        table.insert(groups, layoutGrp)

        -- Group putting it all together.
        local layoutGrp = octane.gui.create 
        {
            type     = octane.gui.componentType.GROUP,
            rows     = 1,
            cols     = 2,
            border   = false,
            children = { leftColGroup,  rightColGroup},
        }
        table.insert(groups, layoutGrp)
    end  

    return octane.gui.create
    { 
        type     = octane.gui.componentType.TABS,
        children = groups,
        header   = captions,
    }
end

materials =
{
    gui    = genGui,
    update = generateMaterial,
}

return materials
