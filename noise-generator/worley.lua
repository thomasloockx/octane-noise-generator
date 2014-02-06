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
-- Just a huge value. 
local HUGE = 2^32

-- more efficient modulo 256
local band   = bit.band
local map256 = function(x)
    return band(x-1, 255) + 1
end

-- Use our own pseudo-random generator. The one that Worly's using relies
-- on overflowing the C value on 32-bit machines -> nasty!
local function LGC(seed)
    return band(1664525 * seed + 1013904223, 2^32-1)
end

local function addSamples(xi, yi, n, p, F)
    -- Each cube has a random number seed based on the cube's ID number.
    -- The seed might be better if it were a nonlinear hash like Perlin uses
    -- for noise but we do very well with this faster simple one.
    -- Our LCG uses Knuth-approved constants for maximal periods.
    local seed = 702395077 * xi + 915488749 * yi

    -- How many feature points are in this cube?
    local count = poissonCount[map256(seed)]

    -- churn the seed with good Knuth LCG
    seed = LGC(seed)

    -- generate each feature point, calc distance and insert it into our solution
    for i=1,count do
        seed = LGC(seed) -- churn

        -- compute the fractional part of the feature point
        local fx = (seed + 0.5) * (1.0 / 4294967296.0); 
        seed = LGC(seed) -- churn
        local fy = (seed + 0.5) * (1.0 / 4294967296.0); 
        seed = LGC(seed) -- churn
        local fz = (seed + 0.5) * (1.0 / 4294967296.0); 
        seed = LGC(seed) -- churn

        -- distance from feature point to sample location
        local dx = xi + fx - p[1];
        local dy = yi + fy - p[2];

        -- Euclidian distance, squared
        local d2 = dx * dx + dy * dy

        -- only bother if the point is closer than what we have so far
        if (d2 < F[n]) then
            -- Insert the information into the output arrays if it's close enough.
            -- We use an insertion sort.  No need for a binary search to find
            -- the appropriate index.. usually we're dealing with order 2,3,4 so
            -- we can just go through the list. If you were computing order 50
            -- (wow!!) you could get a speedup with a binary search 
            
            local index = n
            while index > 1 and d2 < F[index] do index = index - 1 end

            --  We insert this new point into slot # <index> and truncate the table
            table.insert(F, index, d2)
        end
    end
end

-- Returns the n-shortest distances from p to the n feature points.
-- (F1[p]..Fn[p])
--
-- @param[in]   x0
--      x-coord of the point on the grid
-- @param[in]   y0
--      y-coord of the point on the grid
-- @param[in]   n
--      the number of distances to calculate (n)
-- @return
--      table with the distances to the feature points F[1]..F[n]
local function genWorleyNoise2d(x0, y0, n)
    -- table with distances
    local F = {}
    -- Initialize the F values to "huge" so they will be replaced by the
    -- first real sample tests. Note we'll be storing and comparing the
    -- SQUARED distance from the feature points to avoid lots of slow
    -- sqrt() calls. We'll use sqrt() only on the final answer.
    for i=1,n do F[i] = HUGE end
  
    -- Make our own local copy, multiplying to make mean(F[0])==1.0
    local pAdj = { DENSITY_ADJUSTMENT * x0, DENSITY_ADJUSTMENT * y0 }

    -- Find the integer cube holding the hit point
    local pInt = { math.floor(pAdj[1]), math.floor(pAdj[2]) }

    -- TODO: use Worley's smarter approach
    -- Compute the distance to the n closest neighbors in this cell and the surrounding cells.
    for i=-1,1 do
        for j=-1,1 do
           addSamples(pInt[1]+i, pInt[2]+j, n, pAdj, F)
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
