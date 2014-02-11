------------------------------------------------------------------------------
-- Worley Noise Generator, based on Steven Worley's original C-implementation
-- but adapted for the simpler 2D case.

-- A hardwired lookup table to quickly determine how many feature
-- points should be in each spatial cube. We use a table so we don't
-- need to make multiple slower tests.  A random number indexed into
-- this array will give an approximate Poisson distribution of mean
-- density 2.5.
local poissonCount = 
{
    4,3,1,1,1,2,4,2,2,2,5,1,0,2,1,2,2,0,4,3,2,1,2,1,3,2,2,4,2,2,5,1,2,3,2,2,2,2,2,3,
    2,4,2,5,3,2,2,2,5,3,3,5,2,1,3,3,4,4,2,3,0,4,2,2,2,1,3,2,2,2,3,3,3,1,2,0,2,1,1,2,
    2,2,2,5,3,2,3,2,3,2,2,1,0,2,1,1,2,1,2,2,1,3,4,2,2,2,5,4,2,4,2,2,5,4,3,2,2,5,4,3,
    3,3,5,2,2,2,2,2,3,1,1,4,2,1,3,3,4,3,2,4,3,3,3,4,5,1,4,2,4,3,1,2,3,5,3,2,1,3,1,3,
    3,3,2,3,1,5,5,4,2,2,4,1,3,4,1,5,3,3,5,3,4,3,2,2,1,1,1,1,1,2,4,5,4,5,4,2,1,5,1,1,
    2,3,3,3,2,5,2,3,3,2,0,2,1,1,4,2,1,3,2,1,2,2,3,2,5,5,3,4,5,5,2,4,4,5,3,2,2,2,1,4,
    2,3,3,4,2,5,4,2,4,2,2,2,4,5,3,2
}

-- This constant is manipulated to make sure that the mean value of F[0]
-- is 1.0. This makes an easy natural "scale" size of the cellular features.
local DENSITY_ADJUSTMENT = 0.398150
-- max unsigned in value on 32-bit machine
local MAX_INT = 4294967296.0
-- inverse of above value
local INV_MAX_INT = 1.0 / 4294967296.0
-- 32-bit mask, we need this mask to modulo bcoz lua doesn't overflow like C
local M0 = 0xffffffff
-- bitwise and
local band   = bit.band
-- bitwise right shift
local rshift = bit.rshift


-- Calculates the distance of (x, y) to the n-closest feature points
-- in the current cell (xi, yi).
--
--  @param[in]  xi
--      horizontal cell index
--  @param[in]  yi
--      vertical cell index
--  @param[in]  x
--      x coordinate of the input point
--  @param[in[  y
--      y coordinate of the input point
--  @param[in]  n
--      number of distances we're interested in
--  @param[out] F
--      distance the closest, 2nd-closets, n-closest feature point
--      in the current cell
-- @param[out]  ids
--      list of ids, they tell to which feature point this point is assigned.
-- NOTE: Churning of the seed with the LCG from numerical recipes is inlined
--       for performance reasons.
local function calcDistInCell(xi, yi, x, y, n, F, IDs)
    -- Each cube has a random number seed based on the cube's ID number.
    -- The seed might be better if it were a nonlinear hash like Perlin uses
    -- for noise but we do very well with this faster simple one.
    -- Our LCG uses Knuth-approved constants for maximal periods.
    local seed = 702395077 * xi + 915488749 * yi

    -- Check many feature points are in this cube?
    -- We use the high order byte because lower order bytes generated by LCG
    -- are usually less random.
    local nbPoints = poissonCount[rshift(seed, 24)+1]

    seed = band(1664525 * seed + 1013904223, M0) -- churn

    -- Generate each feature point, calc distance and insert it into our solution
    for i=1,nbPoints do
        seed     = band(1664525 * seed + 1013904223, M0) -- churn
        local id = seed
        -- compute the fractional part of this feature point
        local fx = (seed + 0.5) * INV_MAX_INT
        seed = band(1664525 * seed + 1013904223, M0) -- churn
        local fy = (seed + 0.5) * INV_MAX_INT
        seed = band(1664525 * seed + 1013904223, M0) -- churn

        -- distance from feature point to sample location
        local dx = xi + fx - x;
        local dy = yi + fy - y;

        -- Euclidian distance to the feature point, squared.
        local d2 = dx * dx + dy * dy

        -- Only bother if the point is closer than the furthest we've got so far.
        if (d2 < F[n]) then
            -- Look for the right insertion index.
            local ix = 1
            for i=1,n do
                if d2 < F[i] then 
                    ix = i
                    break
                end
            end
            -- bump up everyhing from ix to the end
            for i=n,ix+1 do
                F[i]   = F[i-1]
                IDs[i] = F[i-1]
            end
            F[ix]   = d2
            IDs[ix] = id
        end
    end
end

-- Returns the n-shortest distances from input point p to the feature points.
--
-- @param[in]   x0
--      x-coord of the input point
-- @param[in]   y0
--      y-coord of the input point
-- @param[in]   N 
--      the number of distances to calculate (n)
-- @return
--      table with the distances to the feature points F[1]..F[n] (lenght n)
local function genWorleyNoise2d(x0, y0, n)
    -- Initialize the F values to "huge" so they will be replaced by the
    -- first real sample tests. Note we'll be storing and comparing the
    -- SQUARED distance from the feature points to avoid lots of slow
    -- sqrt() calls. We'll use sqrt() only on the final answer.
    local F   = {}
    local IDs = {}
    for i= 1,n do F[i] = MAX_INT end
  
    -- Make our own local copy, multiplying to make mean(F[0])==1.0
    local x, y = DENSITY_ADJUSTMENT * x0, DENSITY_ADJUSTMENT * y0

    -- Get the integral and fractional part of the x & y coords
    local xi, xf = math.modf(x)
    local yi, yf = math.modf(y)

    -- Smartness: Don't consider neighboring cells where the distance to the next cell
    -- from (x,y) is further away than the distance to the furthest feature point.
    local dxl2 = xf * xf             -- x-distance squared to left cells
    local dxr2 = (1 - xf) * (1 - xf) -- x-distance squared to right cells
    local dyb2 = yf * yf             -- y-distance squared to bottom cells
    local dyt2 = (1 - yf) * (1 - yf) -- y-distance squared to top cells

    -- centre cell
    calcDistInCell(xi, yi, x, y, n , F, IDs)

    -- 4 facing neighbors cells
    if dxl2 < F[n] then calcDistInCell(xi-1, yi  , x, y, n, F, IDs) end -- left
    if dxr2 < F[n] then calcDistInCell(xi+1, yi  , x, y, n, F, IDs) end -- right
    if dyb2 < F[n] then calcDistInCell(xi  , yi-1, x, y, n, F, IDs) end -- bottom
    if dyt2 < F[n] then calcDistInCell(xi  , yi+1, x, y, n, F, IDs) end -- top
    -- 4 corner cells
    if dxl2 + dyb2 < F[n] then calcDistInCell(xi-1, yi-1, x, y, n, F, IDs) end -- bottom-left
    if dxl2 + dyt2 < F[n] then calcDistInCell(xi-1, yi+1, x, y, n, F, IDs) end -- top-left
    if dxr2 + dyb2 < F[n] then calcDistInCell(xi+1, yi-1, x, y, n, F, IDs) end -- bottom-right
    if dxr2 + dyt2 < F[n] then calcDistInCell(xi+1, yi+1, x, y, n, F, IDs) end -- top-right

    -- convert everything to the right size scale
    for i,f in ipairs(F) do v = math.sqrt(f) * (1.0 / DENSITY_ADJUSTMENT) end
    return F, IDs 
end

worley = 
{
    gen2d = genWorleyNoise2d,
}

return worley
