--
-- Copyright (C) 2009-2012 Ivo Wetzel                                           
--                                                                              
-- This file is part of Tuff.                                                   
--                                                                              
-- Tuff is free software: you can redistribute it and/or                        
-- modify it under the terms of the GNU General Public License as published by  
-- the Free Software Foundation, either version 3 of the License, or            
-- (at your option) any later version.                                          
--                                                                              
-- Tuff is distributed in the hope that it will be useful,                      
-- but WITHOUT ANY WARRANTY; without even the implied warranty of               
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the                 
-- GNU General Public License for more details.                                 
--                                                                              
-- You should have received a copy of the GNU General Public License along with 
-- Tuff. If not, see <http://www.gnu.org/licenses/>.                            
--
box = require 'box'

Entity = class('Entity', box.Dynamic)
function Entity:new(x, y, w, h)

    box.Dynamic.new(self, x, y, w, h)

    self.gravity = 0 
    self.gravityAcceleration = 0
    self.jumpForce = 0
    self.jumpDecelaration = 0
    self.movement = { x = 0, y = 0} 
    self.fluidDepth = 0
    self.lastPlatform = nil

    self.maxFallSpeed = 3
    self:fall(self.maxFallSpeed, 0.35)

end

function Entity:jump(height, seconds)

    -- calculate the values for a jump
    local steps = seconds / (1.0 / game.conf.fps)
    local force = height * (1.0 / steps) * 2.0
    self.jumpDecelaration = force / math.max(steps - 1.0, 1.0)
    self.jumpForce = -force

    -- check for platform and correct jump force to include platform y velocity
    if self.contactSurface.down and self.contactSurface.down:is_a(box.Moving) then
        self.jumpForce = self.jumpForce + self.contactSurface.down.vel.y
    end

end

function Entity:fall(maxSpeed, seconds)
    local steps = seconds / (1.0 / game.conf.fps)
    self.gravityAcceleration = maxSpeed / (math.max(steps - 1, 0.1));
end

function Entity:setPosition(x, y)
    box.Dynamic.setPosition(self, x, y)
    self.gravity = 0
    if self.lastPlatform then
        self:detach()
    end
end

function Entity:detach()
    if self.lastPlatform then
        table.delete(self.lastPlatform.contacts, self)
        self.lastPlatform = nil
    end
end

function Entity:update(dt)
    
    -- figure out the water depth
    local inFluid = false
    if self.inside and self.inside.isFluid then
        self.fluidDepth = math.min((self.max.y - 4) - self.inside.min.y, 15)
        inFluid = true
    else
        self.fluidDepth = -1
    end

    box.Dynamic.update(self, dt)

    -- jump forces and gravity are handles differently
    -- this makes the whole system easier and more friendly to gameplay tweaking
    if self.jumpForce < self.maxFallSpeed and self.jumpDecelaration ~= 0 then
        self.jumpForce = self.jumpForce + self.jumpDecelaration 

        -- jumps should not make us move downwards in water, gravity will do that
        if self.fluidDepth > 0 and self.jumpForce > 0 then
            self.vel.y = (self.movement.y * dt) 
            self.gravity = 0
        else
            self.vel.y = (self.movement.y * dt) + self.jumpForce
            self.gravity = self.jumpForce
        end

        if self.contactSurface.down and self.vel.y > 0 then
            self.jumpForce = 0
            self.gravity = 0
        end

    else
        
        -- check whether we're falling
        if not self.contactSurface.down then

            if self.lastPlatform then
                self:detach()
            end

            if not self.inside then
                self.gravity = self.gravity + self.gravityAcceleration
            end

            if self.gravity > self.maxFallSpeed then
                self.gravity = self.maxFallSpeed
            end

        else

            if not inFluid then
                self.gravity = 0.0001
            else
                self.gravity = self.gravity * 0.85
            end

            -- check for platforms and make the entity move downwards with them
            if self.contactSurface.down:is_a(box.Moving) then
                if self.lastPlatform then
                    self:detach()
                end
                self.lastPlatform = self.contactSurface.down
                table.insert(self.lastPlatform.contacts, self)
                self.gravity = self.lastPlatform.vel.y
            end

        end

        -- in water stuff
        if inFluid then

            self.gravity = self.gravity * 0.97
            self.vel.y = -(0.075 * self.fluidDepth) + self.gravity + (self.movement.y * dt)

            if self.fluidDepth <= 1 and math.abs(self.vel.y) < 0.1 then
                self.vel.y = 0
            end

        else
            self.vel.y = (self.movement.y * dt) + self.gravity 
        end

    end

    -- check for platform and x velocity to include platform x velocity
    self.vel.x = (self.movement.x * dt)

    if self.contactSurface.down and self.contactSurface.down:is_a(box.Moving) and not inFluid then

        local mx = self.contactSurface.down.vel.x
        if self.vel.x == 0 or (self.vel.x > 0 and mx > 0) or (self.vel.x < 0 and mx < 0) then
            self.vel.x = (self.movement.x * dt) + mx
        end
        
    end

    if inFluid and self.vel.y > 0 then
        self:detach()
    end

end

function Entity:draw()
    box.Dynamic.draw(self)
end

