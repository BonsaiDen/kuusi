__class_cache = __class_cache or {}

-- class.lua
-- Compatible with Lua 5.1 (not 5.0).
function class(id, base)

    if __class_cache[id] then
        return __class_cache[id]
    end

    -- a new class instance
    local c = {}
    if type(base) == 'table' then

        -- our new class is a shallow copy of the base class!
        for i,v in pairs(base) do
            c[i] = v
        end

        c._base = base
    end
    -- the class will be the metatable for all its objects,
    -- and they will look up their methods in it.
    c.__index = c

    -- expose a constructor which can be called by <classname>(<args>)
    local mt = {}
    mt.__call = function(class_tbl, ...)

        local obj = {}
        setmetatable(obj, c)

        if class_tbl.new then
           class_tbl.new(obj,...)

        else 
            -- make sure that any stuff from the base class is new!
            if base and base.new then
                base.new(obj, ...)
            end
        end

        return obj

    end

    c.new = new
    c.is_a = function(self, klass)

        local m = getmetatable(self)
        while m do 

            if m == klass then 
                return true 
            end

            m = m._base
        end

        return false

    end

    setmetatable(c, mt)
    __class_cache[id] = c

    return c

end
