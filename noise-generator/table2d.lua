------------------------------------------------------------------------------
-- Implementation of a 2D table


local function getValue(self, i, j)
    local ix = self.width * (i - 1) + j
    return self.elems[ix]
end


local function setValue(self, i, j, val)
    local ix = self.width * (i - 1) + j
    self.elems[ix] = val
end


local function create(width, height, def)
    local t = {}
    -- initialize t
    t.width  = width
    t.height = height
    t.set    = setValue
    t.get    = getValue
    t.elems = {}
    return t
end


table2d = 
{
    create = create,
    get    = getValue,
    set    = setValue,
}

return table2d
