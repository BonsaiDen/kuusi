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
require 'Animation'
require 'Entity'

Player = class('Player', Entity)
function Player:new(x, y, w, h)

    image.load('player.png')
    image.setTiles('player.png', 8, 8)

    Entity.new(self, x, y, w, h)

    self.animations = {
        idle = Animation({ 1, 2, 1, 2, 1, 3, 1, 2, 1, 2, 1 }, { 2.5, 0.15, 2, 0.1, 3, 0.6, 2, 0.10, 0.25, 0.10, 4 }, true),
        run = Animation({ 9, 10, 11, 12 }, { 0.045, 0.07, 0.055, 0.07 }, true),

        swim = Animation({ 9, 10, 11, 12 }, { 0.07, 0.12, 0.09, 0.12 }, true),

        sleep = Animation({ 17, 18, 19, 20 }, { 0.9, 1.1, 1.2, 1.1 }, true),
        jump = Animation({ 25, 26 }, { 0.25, 1 }),
        fall = Animation({ 27, 28 }, { 0.25, 1 }),

        rise = Animation({ 25, 26 }, { 1, 1 }),
        dive = Animation({ 27, 28 }, { 0.25, 1 }),

        wallSlide = Animation({33, 34, 35}, {0.10, 0.15, 1})
    }

    self.lastJump = game.getTime()
    self.jumpSpeed = 0

    self.animation = self.animations.idle
    self.lastMove = game.getTime()
    self.lastWallJump = -10
    self.lastWallContact = -10
    self.lastWallDirection = 0

    self.slideStart = 0
    self.drawDirection = self.direction
    self.maxSpeed = 70
    self.accSpeed = 11
    self.decSpeed = 15

    self.pos.z = -1

end

function Player:update(dt)

    local inWater = self.inside and self.inside.isWater

    local now = game.getTime()
    self.animation:update(dt)

    if self.contactSurface.up and not inWater then
        self.jumpForce = 0
        self.gravity = 0
    end

    -- Movement
    local moved = false
    local dec = inWater and self.decSpeed * 0.10 or self.decSpeed
    local acc = inWater and self.accSpeed * 0.25 or self.accSpeed
    local max = inWater and self.maxSpeed * 0.5 or self.maxSpeed

    if keyboard.wasPressed('left') then
        self.direction = -1

    elseif keyboard.wasPressed('right') then
        self.direction = 1
    end

    if now - self.lastWallJump > 0.25 then

        if keyboard.wasPressed('left') then
            self.drawDirection = -1
        elseif keyboard.wasPressed('right') then

            self.drawDirection = 1
        end

        if keyboard.isDown('left') and not self.contactSurface.left then
            self.movement.x = math.max(self.movement.x - acc, -max)
            moved = true

        elseif keyboard.isDown('right') and not self.contactSurface.right then
            self.movement.x = math.min(self.movement.x + acc, max)
            moved = true
        end

    -- wall jump stuff
    else
        dec = dec * 0.5
    end

    if not moved then

        if self.contactSurface.right or self.contactSurface.left then
            self.movement.x = 0
        end

        self.lastMoveSoundPos = now - 0.1
        self.animations.run:reset()
        if self.movement.x > 0 then
            self.movement.x = math.max(0, self.movement.x - dec)

        elseif self.movement.x < 0 then
            self.movement.x = math.min(0, self.movement.x + dec)
        end

    end

    if self.movement.x ~=0 then
        self.lastMove = now
    end

    -- Ground contact / falling
    if self.contactSurface.down then
        self.animations.fall:reset()
        self.animations.wallSlide:reset()

        if self.movement.x ~= 0 then
            self.animation = self.animations.run

        else
            self.animation = self.animations.idle
        end

        self.slideStart = 0

    -- under / in water
    elseif inWater then

        if self.movement.x ~= 0 then
            self.animation = self.animations.swim

        else
            self.animations.swim:reset()
            self.animation = self.animations.idle
        end

        -- dive / rise
        if self.vel.y > 0 then
            self.animation = self.animations.dive

        elseif self.vel.y < 0 then
            self.animation = self.animations.rise

        else
            self.animations.dive:reset()
            self.animations.rise:reset()
        end

    -- normal fall
    elseif self.vel.y > 0 then
        self.animation = self.animations.fall
        self.lastMove = now
    end

    -- impacts
    if self.impactSurface.down then
        --print('hit ground', now - self.lastJump)
    end

    -- Jumping
    if keyboard.wasPressed('s') and not self.contactSurface.up then

        local jump = false
        if now - self.lastWallContact <= 0.1 and self.direction == self.lastWallDirection then
            self.movement.x = 150 * self.direction
            self.lastWallJump = now
            self.lastWallContact = -10
            self.jumpSpeed = 1.9
            jump = true

        elseif self.contactSurface.down then
            self.jumpSpeed = 2.20
            jump = true

        elseif inWater and self.waterDepth < 6 then
            self.jumpSpeed = 2.20
            jump = true
        end

        if jump then
            -- check for platform and correct jump force to include platform y velocity
            --if self.contactSurface.down and self.contactSurface.down:is_a(box.Moving) then
            --    self.jumpForce = self.jumpForce + self.contactSurface.down.vel.y
            --end

            self.slideStart = 0
            self.animations.idle:reset()
            self.animations.fall:reset()
            self.animations.run:reset()
            self.animations.jump:reset()
            self.animation = self.animations.jump
            self.jumpDecelaration = 0.30
            self.lastJump = game.getTime()
            self.lastMove = now
        end
    end

    if keyboard.isDown('s') then
        if now - self.lastJump <= 0.19 then
            self.jumpForce = -self.jumpSpeed
        end

    else
        self.lastJump = 0
    end

    -- Fall asleep after some time
    if now - self.lastMove > 25.0 and not inWater then
        self.animation = self.animations.sleep

    else
        self.animations.sleep:reset()
    end

    Entity.update(self, dt)

    -- Wall sliding / jumps
    if not inWater then

        if self.vel.y > 0.20 and (self.slideStart == 0 or now - self.slideStart < 0.4) then

            if keyboard.isDown('right') and self.contactSurface.right and not self.contactSurface.left and self.contactArea.right == self.size.y then
                self.drawDirection = -1
                self.lastWallDirection = -1
                self.animation = self.animations.wallSlide
                self.lastWallContact = now

                if self.slideStart == 0 then
                    self.slideStart = now
                end

            elseif keyboard.isDown('left') and self.contactSurface.left and not self.contactSurface.right and self.contactArea.left == self.size.y then
                self.drawDirection = 1
                self.lastWallDirection = 1
                self.animation = self.animations.wallSlide
                self.lastWallContact = now

                if self.slideStart == 0 then
                    self.slideStart = now
                end

            else
                self.animations.wallSlide:reset()
            end
            
        end

        -- slide along vertical surfaces
        if self.slideStart ~= 0 then
            local t = 1 - math.min(now - self.slideStart, 0.4) * 2.5
            self.vel.y = self.vel.y * (1 - 0.9 * t)
            if now - self.slideStart < 0.1 then
                self.vel.y = self.vel.y * 0.25
            end
        end

    end

end

function Player:draw(debug)

    local frame = self.animation:getFrame()
    image.drawTile('player.png', math.round(self.pos.x - 3), 
                                 math.round(self.pos.y - 4), 
                                 frame, self.drawDirection == 1)
    if debug then
        Entity.draw(self, debug)
    end

end

