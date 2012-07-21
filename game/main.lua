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
    --game.platform = box.Moving(100, 130,  50, 9)
    --game.platform.blocks.down = false
    --game.platform.blocks.right = false
    --game.platform.blocks.left = false
    --game.platform.vel.y = 0.5

    game.player = Player(35, 120, 10, 12)
    game.manager:add(box.Static(0, 140, 140, 50))

    local c = box.Static( 50, 110, 60, 1)
    c.blocks.down = false
    c.blocks.right = false
    c.blocks.left = false

    game.manager:add(c)

    game.manager:add(box.Static(150, 160, 100, 50))
    game.manager:add(box.Static(200, 50, 60, 200))
    game.manager:add(box.Static(0, 20, 30, 4))
    game.manager:add(box.Static(0, 100, 30, 40))
    game.manager:add(box.Static(200, 0, 50, 50))
    game.manager:add(box.Static(0, 280, 320, 4))

    --game.manager:add(game.platform)
    game.manager:add(game.player)

    game.editor = Editor(game.camera, game.manager)
    game.editor.active = true
    game.pause()

    --sound.load('save.ogg')

end

function game.update(dt, time)

    if keyboard.wasPressed('enter') then

        if not game.isPaused() then
            game.pause()
            game.editor.active = true

        else
            game.resume()
            game.editor.active = false
        end

    end

    if not game.isPaused() then
        game.manager:update(dt)
    end

    -- Editing
    if game.editor.active then
        game.editor:update()

    else
        game.camera.x = math.floor((game.player.pos.x + 7) / game.conf.width) * game.conf.width
        game.camera.y = math.floor(game.player.pos.y / game.conf.height) * game.conf.height
    end

    if keyboard.wasPressed('f5') then
        game.reload()
    end

end

function game.render()

    graphics.setRenderOffset(-game.camera.x, -game.camera.y)
    game.manager:draw(game.camera.x, game.camera.y, game.camera.x + game.conf.width, game.camera.y + game.conf.height, game.editor.active)

    if game.editor.active then
        game.editor:render()
    end

end

