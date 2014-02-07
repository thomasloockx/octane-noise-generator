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

-- maps [1,n] -> [1,256]
local band   = bit.band
local map256 = function(x)
    return band(x-1, 255) + 1
end

-- Use our own pseudo-random generator. The one that Worly uses relies
-- on overflowing the C value on a 32-bit machine.
-- LCG in range [0, 2^32-1]
local function LCG(seed)
    return band(1664525 * seed + 1013904223, M0)
end


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
local function calcDistInCell(xi, yi, x, y, n, F)
    -- Each cube has a random number seed based on the cube's ID number.
    -- The seed might be better if it were a nonlinear hash like Perlin uses
    -- for noise but we do very well with this faster simple one.
    -- Our LCG uses Knuth-approved constants for maximal periods.
    local seed = 702395077 * xi + 915488749 * yi

    -- Check many feature points are in this cube?
    local nbPoints = poissonCount[map256(seed)]

    -- Churn the seed.
    seed = LCG(seed)

    -- Generate each feature point, calc distance and insert it into our solution
    for i=1,nbPoints do
        seed = LCG(seed) -- churn
        -- compute the fractional part of this feature point
        local fx = (seed + 0.5) * INV_MAX_INT
        seed = LCG(seed) -- churn
        local fy = (seed + 0.5) * INV_MAX_INT
        seed = LCG(seed) -- churn

        -- distance from feature point to sample location
        local dx = xi + fx - x;
        local dy = yi + fy - y;

        -- Euclidian distance to the feature point, squared.
        local d2 = dx * dx + dy * dy

        -- Only bother if the point is closer than the furthest we've got so far.
        if (d2 < F[n]) then
            -- Look for the right insertion index.
            local index = n
            while index >= 2 and d2 < F[index-1] do index = index - 1 end
            F[index] = d2
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
    local F = {}
    for i=1,n do F[i] = MAX_INT end
  
    -- Make our own local copy, multiplying to make mean(F[0])==1.0
    local x, y = DENSITY_ADJUSTMENT * x0, DENSITY_ADJUSTMENT * y0

    -- Get the integer fractions to determine in which cell the points are.
    local xi, yi = math.floor(x), math.floor(y)

    -- TODO: use Worley's smarter approach
    -- Compute the distance to the n closest neighbors in this cell and the 
    -- surrounding cells.
    for i=-1,1 do
        for j=-1,1 do
           calcDistInCell(xi + i, yi + j, x, y, n, F)
        end
    end

  -- We're done! Convert everything to right size scale
  for i,f in ipairs(F) do v = math.sqrt(f) * (1.0 / DENSITY_ADJUSTMENT) end

  return F
end

worley = 
{
    gen2d = genWorleyNoise2d,
}

return worley
