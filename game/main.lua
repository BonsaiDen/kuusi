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
require 'class'

box = require 'box'
require 'Player'
require 'Editor'


-- test debug stuff
Block = class('Block', box.Static)
function Block:new(x, y, w, h)
    box.Static.new(self, x, y, w, h)
    self.isFluid = false
end

function Block:setType(typ)

    if typ == 'water' then
        self.isFluid = true
        self.blocks.left = false
        self.blocks.up = false
        self.blocks.down = false
        self.blocks.right = false

    else
        self.isFluid = true
        self.blocks.left = true
        self.blocks.up = true
        self.blocks.down = true
        self.blocks.right = true
    end

end

function Block:draw(debug)

    if self.isFluid then
        local t = math.max(0, math.cos(game.getTime()) + 1) / 2
        graphics.setColor(16 + 32 * t / 2, 16 + 32 * t / 2, 255, 0.90 - t / 10)
        graphics.rect(self.pos.x, self.pos.y, self.size.x, self.size.y, true)

    else
        box.Static.draw(self, debug)
    end

end


Platform = class('Platform', box.Moving)
function Platform:new(x, y, w, h, points)

    self.speed = 0.6
    box.Moving.new(self, x, y, w, h)
    self.blocks.down = false
    self.blocks.right = false
    self.blocks.left = false

    self.contacts = {}
    self.waypoints = points or { { x, y } }
    self.direction = 1
    self.toDirection = self.direction
    self.point = 2

    self:reset()

end

function Platform:reset()
    local start = self.waypoints[self.point]
    self.toDirection = self.direction
    self:setPosition(start[1] - self.size.x / 2, start[2] - self.size.y / 2)
end

function Platform:update(dt)

    box.Moving.update(self)

    local from = self.waypoints[self.point]
    local to = self.waypoints[self.point + self.toDirection]

    --local dist = math.sqrt(dx * dx + dy * dy)
    local dx = to[1] - (self.pos.x + self.size.x / 2)
    local dy = to[2] - (self.pos.y + self.size.y / 2)
    local r = math.atan2(dy, dx)
    local vx = math.cos(r) * self.speed
    local vy = math.sin(r) * self.speed

    if vx < 0 then
        vx = math.max(dx, vx)

    elseif vx > 0 then
        vx = math.min(dx, vx)
    end

    if vy < 0 then
        vy = math.max(dy, vy)

    elseif vy > 0 then
        vy = math.min(dy, vy)
    end

    self.vel.x = vx
    self.vel.y = vy

    if vx == 0 and vy == 0 then
        self.point = self.point + self.toDirection
        if self.point == #self.waypoints then
            self.toDirection = -1

        elseif self.point == 1 then
            self.toDirection = 1
        end
    end

    for i=1,#self.contacts do

        local c = self.contacts[i]
        c.vel.y = vy

        if c.vel.x == 0 or (c.vel.x > 0 and vx > 0) or (c.vel.x < 0 and vx < 0) then
            c.vel.x = (c.movement.x * dt) + vx
        end

    end

end

function Platform:draw(debug)

    box.Moving.draw(self, debug)
    
    if debug then
        graphics.setColor(25, 100, 75)
        local last = self.waypoints[1]
        for i=2,#self.waypoints do
            local point = self.waypoints[i]
            graphics.line(last[1], last[2], point[1], point[2])
            last = point
        end
    end

end


function game.init(conf)
    conf.title = "Kuusi"
    conf.width = 256
    conf.height = 144
    conf.scale = 3
    conf.fps = 60
end


function game.load(arg)

    graphics.setBackgroundColor(64, 64, 64)

    game.camera = {
        x = 0,
        y = 0
    }

    game.manager = box.Manager()
    game.platform = box.Moving(100, 130,  50, 9)
    game.platform.blocks.down = false
    game.platform.blocks.right = false
    game.platform.blocks.left = false
    game.platform.vel.y = -1

    game.player = Player(35, 120, 10, 12)
    game.manager:add(Block(0, 140, 140, 50))

    local c = Block( 50, 110, 60, 1)
    c.blocks.down = false
    c.blocks.right = false
    c.blocks.left = false

    game.manager:add(c)

    game.manager:add(Block(150, 160, 100, 50))
    game.manager:add(Block(200, 50, 60, 200))
    game.manager:add(Block(0, 20, 30, 4))
    game.manager:add(Block(0, 100, 30, 40))
    game.manager:add(Block(200, 0, 50, 50))
    game.manager:add(Block(0, 280, 320, 4))

    local water = Block(10, 100, 240, 100)
    water:setType('water')
    game.manager:add(water)

    game.manager:add(Platform(64, 32, 32, 4, {
        { 64, 32 },
        { 100, 32 },
        { 100, 64 },
        { 200, 64 }
    }))

    game.manager:add(game.player)

    game.editor = Editor(game.camera, game.manager)
    game.edit(true)
    game.pause()

    --sound.load('save.ogg')

end

function game.update(dt, time)

    if keyboard.wasPressed('enter') then
        game.edit()
    end

    if not game.isPaused() then
        game.manager:update(dt)
    end

    -- Editing
    if game.editor.active then
        game.editor:update()

    else
        game.camera.x = math.floor((game.player.pos.x + 4) / game.conf.width) * game.conf.width
        game.camera.y = math.floor(game.player.pos.y / game.conf.height) * game.conf.height
    end

    if keyboard.wasPressed('f5') then
        game.reload()
    end

end

function game.render()

    if game.editor.active then
        graphics.setRenderOffset(-game.camera.x + 16, -game.camera.y + 16)
        game.manager:draw(game.camera.x - 16, game.camera.y - 16, game.camera.x + game.conf.width + 16, game.camera.y + game.conf.height + 16, game.editor.active)

    else
        graphics.setRenderOffset(-game.camera.x, -game.camera.y)
        game.manager:draw(game.camera.x, game.camera.y, game.camera.x + game.conf.width, game.camera.y + game.conf.height, game.editor.active)
    end

    if game.editor.active then
        game.editor:render()
    end

end

function game.edit(mode)

    if not game.isPaused() or mode == true then
        game.pause()
        graphics.setSize(256 + 32, 144 + 32)
        game.editor.active = true

    elseif game.isPaused() or mode == false then
        graphics.setSize(256, 144)
        game.resume()
        game.editor.active = false
    end

end

