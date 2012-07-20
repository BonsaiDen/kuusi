--
-- Copyright (c) 2012 Ivo Wetzel.
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--

-- ----------------------------------------------------------------------------
-- Static AABB Box ------------------------------------------------------------
-- ----------------------------------------------------------------------------
local StaticBox = StaticBox or class()
StaticBox.id = 0

function StaticBox:new(x, y, w, h, z)
    self.id = StaticBox.id
    StaticBox.id = StaticBox.id + 1

    self.pos = { x = x, y = y , z = z or 0 }
    self.size = { x = w, y = h }

    self.vel = { x = 0, y = 0 }
    self.min = { x = 0, y = 0 }
    self.max = { x = 0, y = 0 }

    self.blocks = {
        up = true,
        right = true,
        down = true,
        left = true
    }

    self:updateBounds()
end

function StaticBox:setPosition(x, y)
    self.pos.x = math.round(x)
    self.pos.y = math.round(y)
    self:updateBounds()
end

function StaticBox:updateBounds()
    self.max.x = math.round(self.pos.x + self.size.x)
    self.min.x = math.round(self.pos.x)
    self.max.y = math.round(self.pos.y + self.size.y)
    self.min.y = math.round(self.pos.y)
end

function StaticBox:overlaps(other)
    if self.max.x < other.min.x or self.min.x > other.max.x then 
        return false

    elseif self.max.y < other.min.y or self.min.y > other.max.y then 
        return false 

    else
        return true
    end
end

function StaticBox:overlapArea(other)
    local xo = math.max(0, math.min(self.max.x, other.max.x) - math.max(self.min.x, other.min.x))
    local yo = math.max(0, math.min(self.max.y, other.max.y) - math.max(self.min.y, other.min.y))
    return xo * yo
end

function StaticBox:within(x, y, mx, my)
    return self.min.x < mx and self.min.y < my
            and self.max.x > x and self.max.y > y
end

function StaticBox:contains(x, y)
    return self.min.x <= x and self.min.y <= y
            and self.max.x >= x and self.max.y >= y
end

function StaticBox:draw(debug)

    local c = 160 - self.pos.z * 10
    graphics.setColor(c, c, c)
    graphics.rect(self.pos.x, self.pos.y, self.size.x, self.size.y)

    graphics.setColor(c, c, c)
    graphics.rect(self.pos.x + 1, self.pos.y + 1, self.size.x - 2, self.size.y - 2, true)

    if debug then
        graphics.setColor(200, 0, 0)

        if self.blocks.up then
            graphics.line(self.pos.x, self.pos.y, self.pos.x + self.size.x, self.pos.y)
        end

        if self.blocks.down then
            graphics.line(self.pos.x, self.pos.y + self.size.y - 1, self.pos.x + self.size.x, self.pos.y + self.size.y - 1)
        end

        if self.blocks.left then
            graphics.line(self.pos.x, self.pos.y, self.pos.x, self.pos.y + self.size.y - 1)
        end

        if self.blocks.right then
            graphics.line(self.pos.x + self.size.x - 1, self.pos.y, self.pos.x + self.size.x - 1, self.pos.y + self.size.y - 1)
        end

    end

end
-- End Static ------------------------------------------------------------------



-- ----------------------------------------------------------------------------
-- Static Box Grid ------------------------------------------------------------
-- ----------------------------------------------------------------------------
local StaticBoxGrid = StaticBoxGrid or class()
function StaticBoxGrid:new(spacing)
    -- this should be bigger then the maximum square size of any dynamic object
    self.spacing = spacing or 64 
    self.buckets = {}
    self.empty = {}

    self.boxes = {}
end

function StaticBoxGrid:add(box)

    table.insert(self.boxes, box)
    self:eachIn(box.min.x, box.min.y, box.max.x, box.max.y, function(x, y, hash)
    
        if not self.buckets[hash] then
            self.buckets[hash] = {}
        end
        table.insert(self.buckets[hash], box)

    end)

end

function StaticBoxGrid:remove(box)

    table.delete(self.boxes, box)
    self:eachIn(box.min.x, box.min.y, box.max.x, box.max.y, function(x, y, hash)
    
        if not self.buckets[hash] then
            self.buckets[hash] = {}
        end
        table.delete(self.buckets[hash], box)

    end)

end

function StaticBoxGrid:eachIn(x, y, mx, my, callback)
    local minx = math.floor(x / self.spacing) * self.spacing - self.spacing
    local maxx = math.floor(mx / self.spacing) * self.spacing + self.spacing

    local miny = math.floor(y / self.spacing) * self.spacing - self.spacing
    local maxy = math.floor(my / self.spacing) * self.spacing + self.spacing

    for y=miny, maxy, self.spacing do
        for x=minx, maxx, self.spacing do
            local hash = self:hash(x, y)
            if callback(x, y, hash, self:get(x, y)) then
                return true
            end
        end
    end
end

function StaticBoxGrid:hash(x, y)
    return math.floor(x / self.spacing) * (self.spacing * 8) + math.floor(y / self.spacing)
end

function StaticBoxGrid:get(x, y)
    return self.buckets[self:hash(x, y)] or self.empty
end
-- End Dynamic ----------------------------------------------------------------



-- ----------------------------------------------------------------------------
-- Moving AABB Box ------------------------------------------------------------
-- ----------------------------------------------------------------------------
local MovingBox = MovingBox or class(StaticBox)
function MovingBox:new(x, y, w, h)
    StaticBox.new(self, x, y, w, h)
end

function MovingBox:update(dt)
    self.pos.x = self.pos.x + self.vel.x
    self.pos.y = self.pos.y + self.vel.y
    self:updateBounds()
end

function MovingBox:draw()
    local x = self.pos.x
    local y = self.pos.y
    local sx = self.size.x
    local sy = self.size.y
    local cx = x + sx / 2
    local cy = y + sy / 2
    local vx = self.vel.x
    local vy = self.vel.y
    local vl = math.sqrt(vx * vx + vy * vy)

    graphics.setColor(0, 255, 0)
    graphics.rect(x, y, sx, sy)

    graphics.setColor(0, 0, 255)
    graphics.line(cx, cy, cx + vx / vl * 10, cy + vy / vl * 10, 2)

end
-- End Moving -----------------------------------------------------------------



-- ----------------------------------------------------------------------------
-- Dynamic AABB Box -----------------------------------------------------------
-- ----------------------------------------------------------------------------
local DynamicBox = DynamicBox or class(StaticBox)
function DynamicBox:new(x, y, w, h)
    StaticBox.new(self, x, y, w, h)

    -- TODO these should to be lists 
    self.oldSurface = {
        up = nil,
        right = nil,
        down = nil,
        left = nil
    }

    self.contactSurface = {
        up = nil,
        right = nil,
        down = nil,
        left = nil
    }

    self.contactArea = {
        up = 0,
        right = 0,
        down = 0,
        left = 0
    }

    self.impactSurface = {
        up = nil,
        right = nil,
        down = nil,
        left = nil
    }
end

function DynamicBox:beforeUpdate(dt)
    self.oldSurface.up = self.contactSurface.up
    self.oldSurface.down = self.contactSurface.down
    self.oldSurface.right = self.contactSurface.right
    self.oldSurface.left = self.contactSurface.left

    self.impactSurface.up = nil
    self.impactSurface.down = nil
    self.impactSurface.right = nil
    self.impactSurface.left = nil

    self.contactSurface.up = nil
    self.contactSurface.down = nil
    self.contactSurface.right = nil
    self.contactSurface.left = nil

    self.contactArea.up = 0
    self.contactArea.down = 0
    self.contactArea.right = 0
    self.contactArea.left = 0
end

function DynamicBox:update(dt)
    self:updatePosition(dt)
    self:updateBounds()
end

function DynamicBox:updatePosition(dt)
    self.pos.x = self.pos.x + self.vel.x
    self.pos.y = self.pos.y + self.vel.y
end

function DynamicBox:setPosition(x, y) 
    self.pos.x = math.round(x)
    self.pos.y = math.round(y)
    self.vel.x = 0
    self.vel.y = 0
    self:updateBounds()
end

function DynamicBox:draw(debug)
    local x = self.pos.x
    local y = self.pos.y
    local sx = self.size.x
    local sy = self.size.y
    local cx = x + sx / 2
    local cy = y + sy / 2
    local vx = self.vel.x
    local vy = self.vel.y
    local vl = math.sqrt(vx * vx + vy * vy)
    if vl == 0 then
        vl = 1
    end

    graphics.setColor(255, 255, 0)
    graphics.rect(x, y, sx, sy)

    graphics.setColor(0, 0, 255)
    graphics.line(cx, cy, cx + vx / vl * 10, cy + vy / vl * 10)

    graphics.setColor(0, 0, 255)
    if self.contactSurface.down then
        graphics.line(x, y + sy - 1, x + sx, y + sy - 1)
    end

    if self.contactSurface.up then
        graphics.line(x, y, x + sx, y)
    end

    if self.contactSurface.left then
        graphics.line(x, y, x, y + sy)
    end

    if self.contactSurface.right then
        graphics.line(x + sx - 1, y, x + sx - 1, y  + sy)
    end

end

function DynamicBox:onCollision(other, vel, normal)

    self.vel.x = self.vel.x + vel.x
    self.vel.y = self.vel.y + vel.y

    if self.contactSurface.down and not self.oldSurface.down then
        self.impactSurface.down = other
    end

    if self.contactSurface.up and not self.oldSurface.up then
        self.impactSurface.up = other
    end

    if self.contactSurface.left and not self.oldSurface.left then
        self.impactSurface.left = other
    end

    if self.contactSurface.right and not self.oldSurface.right then
        self.impactSurface.right = other
    end

end

function DynamicBox:sweep(other, otherVel)
    local a = self
    local b = other
    local v = { x = a.vel.x - b.vel.x, y = a.vel.y - b.vel.y }

    if otherVel then
        v.x = v.x + otherVel.x
        v.y = v.y + otherVel.y
    end

    local hitTime = 0
    local outTime = 1
    local overlapsTime = {
        x = 0,
        y = 0
    }

    local outVel = { x = 0, y = 0 }

    -- invert v, since we're treating b as stationary here
    v.x = -v.x
    v.y = -v.y
    
    -- X axis overlap
    if v.x < 0 then
        if b.max.x < a.min.x then return false, nil, nil end
        if b.max.x > a.min.x then
            outTime = math.min((a.min.x - b.max.x) / v.x, outTime)
        end

        if a.max.x < b.min.x then
            overlapsTime.x = (a.max.x - b.min.x) / v.x
            hitTime = math.max(overlapsTime.x, hitTime)
        end

    elseif v.x > 0 then
        if b.min.x > a.max.x then return false, nil, nil end
        if a.max.x > b.min.x then
            outTime = math.min((a.max.x - b.min.x) / v.x, outTime)
        end

        if b.max.x < a.min.x then
            overlapsTime.x = (a.min.x - b.max.x) / v.x
            hitTime = math.max(overlapsTime.x, hitTime)
        end

    end

    if hitTime > outTime then return false, nil, nil end

    -- Y axis overlap
    if v.y < 0 then
        if b.max.y < a.min.y then return false, nil, nil end
        if b.max.y > a.min.y then
            outTime = math.min((a.min.y - b.max.y) / v.y, outTime)
        end

        if a.max.y < b.min.y then
            overlapsTime.y = (a.max.y - b.min.y) / v.y
            hitTime = math.max(overlapsTime.y, hitTime)
        end

    elseif v.y > 0 then
        if b.min.y > a.max.y then return false, nil, nil end
        if a.max.y > b.min.y then
            outTime = math.min((a.max.y - b.min.y) / v.y, outTime)
        end

        if b.max.y < a.min.y then
            overlapsTime.y = (a.min.y - b.max.y) / v.y
            hitTime = math.max(overlapsTime.y, hitTime)
        end

    end

    if hitTime > outTime then return false, nil, nil end

    -- the correction to the current velocity
    outVel.x = (v.x - (v.x * hitTime))
    outVel.y = (v.y - (v.y * hitTime))

    -- IMPORTANT
    -- since hitTime defaults to 0, everything that's
    -- somehwere along an axis will eventually collided at "0"
    -- thus, we bail out in case of <= 0 to prevent "ghosting" collisions
    -- BUT: In order to stop at objects, we need to NOT bail out in case we overlap
    if (hitTime <= 0 and not a:overlaps(b)) or hitTime > 1 or hitTime > outTime then 
        return false, nil, nil
    end

    -- allow for sliding on surfaces
    if a.max.y - b.min.y == 0 or a.min.y - b.max.y == 0 then
        outVel.x = 0
    end

    if a.max.x - b.min.x == 0 or a.min.x - b.max.x == 0 then
        outVel.y = 0
    end

    local hitNormal = {
        x = (outVel.x < 0) and 1 or ((outVel.x > 0) and -1 or 0),
        y = (outVel.y < 0) and 1 or ((outVel.y > 0) and -1 or 0)
    }

    -- allow us to get away if we're in contact but are moving into the opposite
    -- direction
    if hitTime == 0 then

        -- return false in case we're trying to move away
        if v.x > 0 and a.max.x <= b.min.x then
            return false, nil, nil

        elseif v.x < 0 and a.min.x >= b.max.x then
            return false, nil, nil
        end

        if v.y > 0 and a.max.y <= b.min.y then
            return false, nil, nil

        elseif v.y < 0 and a.min.y >= b.max.y then
            return false, nil, nil
        end

        -- otherwise set the contact surface
        if a.min.x < b.max.x and a.max.x > b.min.x then

            local area = 0
            if a.min.x >= b.min.x and a.max.x <= b.max.x then
                area = a.size.x

            elseif a.min.x < b.min.x then
                area = a.max.x - b.min.x

            elseif a.max.x > b.max.x then
                area = b.max.x - a.min.x
            end

            area = math.min(math.min(a.size.x, b.size.x), area)

            if a.max.y == b.min.y and b.blocks.up then
                self.contactSurface.down = b
                self.contactArea.down = self.contactArea.down + area

            elseif a.min.y == b.max.y and b.blocks.down then
                self.contactSurface.up = b
                self.contactArea.up = self.contactArea.up + area
            end
        end

        if a.min.y < b.max.y and a.max.y > b.min.y then

            local area = 0
            if a.min.y >= b.min.y and a.max.y <= b.max.y then
                area = a.size.y

            elseif a.min.y < b.min.y then
                area = a.max.y - b.min.y

            elseif a.max.y > b.max.y then
                area = b.max.y - a.min.y
            end

            area = math.min(math.min(a.size.y, b.size.y), area)

            if a.max.x == b.min.x and b.blocks.right then
                self.contactSurface.right = b
                self.contactArea.right = self.contactArea.right + area

            elseif a.min.x == b.max.x and b.blocks.left then
                self.contactSurface.left = b
                self.contactArea.left = self.contactArea.left + area
            end
        end

        -- in case we're stuck make sure push us out
        local pushVel = {
            x = 0,
            y = 0
        }

        local acy = a.min.y + a.size.y / 2
        local bcy = b.min.y + b.size.y / 2

        local acx = a.min.x + a.size.x / 2
        local bcx = b.min.x + b.size.x / 2

        if math.abs(acx - bcx) < (a.size.x + b.size.x) / 2 and math.abs(acy - bcy) < (a.size.y + b.size.y) / 2 then

            if acy < bcy then
                pushVel.y = b.min.y - a.max.y

            else
                pushVel.y = b.max.y - a.min.y
            end

            if acx < bcx then
                pushVel.x = b.min.x - a.max.x

            else
                pushVel.x = b.max.x - a.min.x
            end

            -- handle non blocking edges
            if pushVel.x < 0 and not b.blocks.right and v.x >= 0 then
                pushVel.x = 0

            elseif pushVel.x > 0 and not b.blocks.left and v.x <= 0 then
                pushVel.x = 0
            end

            if pushVel.y < 0 and not b.blocks.down and v.y >= 0 then
                pushVel.y = 0

            elseif pushVel.y > 0 and not b.blocks.up and v.y <= 0 then
                pushVel.y = 0
            end


            -- Correct all possible floating point issues
            if pushVel.y > 0 then
                pushVel.y = math.max(1, pushVel.y)

            elseif pushVel.y < 0 then
                pushVel.y = math.min(-1, pushVel.y)
            end

            if pushVel.x > 0 then
                pushVel.x = math.max(1, pushVel.x)

            elseif pushVel.x < 0 then
                pushVel.x = math.min(-1, pushVel.x)
            end


            -- now choose the minium / maximum of the push / out values
            -- to resolve the stuck state in the "best" way
            if pushVel.y ~=0 and math.abs(pushVel.y) < math.abs(pushVel.x) then
                outVel.y = outVel.y + pushVel.y

            elseif pushVel.x ~=0 and math.abs(pushVel.x) < math.abs(pushVel.y) then
                outVel.x = outVel.x + pushVel.x

            else
                outVel.y = outVel.y + pushVel.y
                outVel.x = outVel.x + pushVel.x
            end

        end

    end

    -- in case the block isn't blocking in specific directions+
    -- reset the out velocity

    -- up / down
    if outVel.y > 0 and not b.blocks.down and v.y >= 0 then
        outVel.y = 0

    elseif not b.blocks.down and v.y >= 0 then
        outVel.y = 0

    elseif outVel.y < 0 and not b.blocks.up and v.y <= 0 then
        outVel.y = 0

    elseif not b.blocks.up and v.y <= 0 then
        outVel.y = 0
    end

    -- left / right
    if outVel.x > 0 and not b.blocks.right and v.x >= 0 then
        outVel.x = 0

    elseif not b.blocks.right and v.x >= 0 then
        outVel.x = 0

    elseif outVel.x < 0 and not b.blocks.left and v.x >= 0 then
        outVel.x = 0

    elseif not b.blocks.left and v.x <= 0 then
        outVel.x = 0
    end

    if a.max.y > b.min.y and not b.blocks.down then
        outVel.y = 0
    end


    -- more crazy stuff
    --if outVel.y < 0 and  and not b.blocks.down then
    --end

    -- final correction for ghosting artifacts
    if outVel.y ~= 0 and not (a.min.x < b.max.x and a.max.x > b.min.x) then

        -- only return in case x is also 0, otherwise we'll clip into walls
        -- in case of diagonal movement
        if outVel.x == 0 then
            return false, nil, nil

        else
            hitNormal.y = 0
            outVel.y = 0
        end

    end

    if outVel.x ~= 0 and not (a.min.y < b.max.y and a.max.y > b.min.y) then

        -- only return in case x is also 0, otherwise we'll clip into floors
        -- in case of diagonal movement
        if outVel.y == 0 then
            return false, nil, nil

        else
            hitNormal.x = 0
            outVel.x = 0
        end

    end

    return true, outVel, hitNormal 

end
-- End Dynamic ----------------------------------------------------------------



-- ----------------------------------------------------------------------------
-- Box Manager ----------------------------------------------------------------
-- ----------------------------------------------------------------------------
local BoxManager = BoxManager or class()

function BoxManager:new()
    self.dynamics = {}
    self.movings = {}
    self.staticGrid = StaticBoxGrid(64)
end

function BoxManager:add(box)
    if box:is_a(DynamicBox) then
        table.insert(self.dynamics, box)

    elseif box:is_a(MovingBox) then
        table.insert(self.movings, box)

    else
        self.staticGrid:add(box)
    end
end

function BoxManager:remove(box)
    if box:is_a(DynamicBox) then
        table.delete(self.dynamics, box)

    elseif box:is_a(MovingBox) then
        table.delete(self.movings, box)

    else
        self.staticGrid:remove(box)
    end
end

table.delete = function(t, item)

    local index = table.find(t, item)
    if index > 0 then
        table.remove(t, index)
        return true

    else
        return false
    end

end

table.find = function(t, item)

    for i=1, #t do
        if t[i] == item then
            return i
        end
    end

    return 0

end

function BoxManager:update(dt)
    --table.sort(self.dynamics, function(a, b)
        --if a.pos.y > b.pos.y then
            --return true

        --elseif b.pos.y < a.pos.y then
            --return false
        --end
    --end)

    for i=1, #self.dynamics do
        self.dynamics[i]:beforeUpdate(dt)
    end

    -- collide all dynamics against all statics
    for i=1, #self.dynamics do

        local box = self.dynamics[i]

        -- now check all static dynamics in the same area
        local statics = self.staticGrid:get(box.pos.x, box.pos.y)
        for e=1, #statics do

            local col, vel, normal = box:sweep(statics[e])

            if col then
                box:onCollision(statics[e], vel, normal)
            end

        end

    end

    for i=1, #self.dynamics do

        local box = self.dynamics[i]

        -- now check all static dynamics in the same area
        for e=1, #self.movings do

            local col, vel, normal = box:sweep(self.movings[e])

            if col then
                box:onCollision(self.movings[e], vel, normal)
            end

        end

    end

    -- now update all dynamic and movings boxes 
    for i=1, #self.dynamics do
        self.dynamics[i]:update(dt)
    end

    -- collide all dynamics with each other
    -- the problematic part here is to know
    -- that the relative velocities of the boxes are in play
    -- so we need to make sure that a box which is hit, checks 
    --for i=1, #self.dynamics do

        --local box = self.dynamics[i]
        --local col, vel, normal = self:collideBox(box)

        --if col then
            --box:onCollision(col, vel, normal)
        --end

    --end
    

    for i=1, #self.movings do
        self.movings[i]:update(dt)
    end
end

function BoxManager:collideBox(box, ignore)
    for e=1, #self.dynamics do

        local other = self.dynamics[e]
        if other ~= box then

            local col, vel, normal = box:sweep(other)
            if col then
                
                --if other ~= ignore then
                    --local ocol, ovel, onormal = self:collideBox(other, box)
                    --print(vel.y, ovel.y)
                    --vel.y = vel.y - ovel.y * 2
                --end

                return other, vel, normal

            end

        end

    end
end

function BoxManager:eachIn(x, y, mx, my, callback)
    
    local filtered = {}

    self.staticGrid:eachIn(x, y, mx, my, function(x, y, hash, statics)
        for e=1, #statics do
            local box = statics[e]
            if not filtered[box.id] then
                if callback(box) then
                    return true
                end
                filtered[box.id] = true
            end
        end
    end)

    for i=1, #self.movings do
        if self.movings[i]:within(x, y, mx, my) then
            local box = self.movings[i]
            if not filtered[box.id] then
                if callback(box) then
                    return true
                end
                filtered[box.id] = true
            end
        end
    end

    for i=1, #self.dynamics do
        if self.dynamics[i]:within(x, y, mx, my) then
            local box = self.dynamics[i]
            if not filtered[box.id] then
                if callback(box) then
                    return true
                end
                filtered[box.id] = true
            end
        end
    end
end

function BoxManager:draw(x, y, mx, my, debug)

    local boxes = {}
    self:eachIn(x, y, mx, my, function(box)
        table.insert(boxes, box)
    end)

    table.sort(boxes, function(a, b)
        return a.pos.z < b.pos.z
    end)

    for i=1,#boxes do
        boxes[i]:draw(debug)
    end

end
-- End Manager ----------------------------------------------------------------



return {
    Static= StaticBox,
    Dynamic= DynamicBox,
    Moving= MovingBox,
    Manager = BoxManager
}

