------------------------------------------------------------------------------
-- Perlin Noise Generator, based on Ken Perlin's original C-implementation.

local N_GRADS      = 256
local INV_SQRT_1_2 = 1.0 / math.sqrt(0.5)

-- Global table with permutations of [0, N_GRADS] and the gradients.
local P, G = {}, {}

-- s-curve smoothing interpolation
local function sCurve(t)
    return t * t * (3. - 2. * t)
end

-- linear interpolation
local function lerp(t, a, b)
    return  a + t * (b - a)
end

-- generates the permutations and the gradients
local function noiseInit(p, g, N)

    -- permutes a list
    local permute = function(l)
        local len = #l
        for i=1,len do
            local j = math.random(len)
            local t = l[j]
            l[j]    = l[i]
            l[i]    = t
        end
    end

    -- table of permuted indices
    for i=1,N do table.insert(p, i) end
    permute(p)

    -- Generates a list of 256 2D gradient vectors.
    local genGrads = function (gradients, n)
        for i=1,n do 
            -- Gen points with a circular distribution.
            local x, y = 1, 1
            while true do
                x = 2 * math.random() - 1
                y = 2 * math.random() - 1
                if x*x + y*y < 1 then
                    break
                end
            end

            -- normalize gradient vec
            local len = math.sqrt(x*x + y*y)
            x = x / len
            y = y / len

            table.insert(gradients, { x, y })
        end
    end

    genGrads(g, N)

    -- double p and g to save out 4 modulo operations
    local len = #p
    for i=1,len do p[len + i] = p[i] end
    for i=1,len do g[len + i] = g[i] end
end

-- Generates perlin noise for point (x,y) with x and y greater than 1
-- noise value is in [0, 1]
local function noise2D(x, y)

    -- integer and fractional parts of x and y
    local ix = math.floor(x)
    local iy = math.floor(y)
    local fx = x - ix
    local fy = y - iy

    local band   = bit.band
    local map256 = function(x)
        return band(x-1, 255) + 1
    end

    -- find grid cell bounds Q in [1,256]
    local bx0 = map256(ix)
    local bx1 = map256(ix+1)
    local by0 = map256(iy)
    local by1 = map256(iy+1)

    -- coords of (P-Q) (distance from cell corners)
    local dx0 = x - ix
    local dx1 = dx0 - 1
    local dy0 = y - iy
    local dy1 = dy0 - 1

    -- get the gradient index for each cell corner
    local i   = P[bx0]
    local j   = P[bx1]
    local b00 = P[i+by0]
    local b10 = P[j+by0]
    local b01 = P[i+by1]
    local b11 = P[j+by1]

    -- get the actual gradients
    local g00 = G[b00]
    local g10 = G[b10]
    local g01 = G[b01]
    local g11 = G[b11]

    -- calculate the dot products
    local dot00 = dx0 * g00[1] + dy0 * g00[2]
    local dot10 = dx1 * g10[1] + dy0 * g10[2]
    local dot01 = dx0 * g01[1] + dy1 * g01[2]
    local dot11 = dx1 * g11[1] + dy1 * g11[2]

    -- calculate interpolation weights via the s-curve
    local sx = sCurve(dx0)
    local sy = sCurve(dy0)

    -- interpolate the dot products to get the noise value
    local a     = lerp(sx, dot00, dot10)
    local b     = lerp(sx, dot01, dot11)
    local noise = lerp(sy, a, b)

    -- [-sqrt(0.5), +sqrt(0.5)] -> [0, 1]
    return 2 * (noise * INV_SQRT_1_2) - 1
end

-- Initialize the permutation and gradient arrays.
noiseInit(P, G, N_GRADS)

perlin = 
{
    gen2d = noise2D
}

return perlin
