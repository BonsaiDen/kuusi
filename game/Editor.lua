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
Editor = class('Editor')

function Editor:new(camera, manager)
    self.camera = camera
    self.manager = manager
    self.active = false

    -- box editing 
    self.selected = nil
    self.hovered = nil
    self.isMoving = false
    self.isSizing = false

    self.create = false
    self.mouseOffsetX = 0
    self.mouseOffsetY = 0

    self.boxOffsetX = 0
    self.boxOffsetY = 0

    self.boxBase = {}
    self.edge = 0

end


function Editor:update()
    
    local ox, oy = graphics.getRenderOffset()
    graphics.setRenderOffset(-self.camera.x, -self.camera.y)

    -- Camera / Box movement
    local moveBy = keyboard.isDown('lshift') and 16 or 1
    local down = mouse.isDown('l')
    if keyboard.wasPressed('left') then
        if not self.selected or down then
            self.camera.x = self.camera.x - game.conf.width
            moveBy = game.conf.width
        end

        if self.selected then
            self.selected:setPosition(self.selected.pos.x - moveBy, self.selected.pos.y)
        end

    elseif keyboard.wasPressed('right') then
        if not self.selected or down then
            self.camera.x = self.camera.x + game.conf.width
            moveBy = game.conf.width
        end

        if self.selected then
            self.selected:setPosition(self.selected.pos.x + moveBy, self.selected.pos.y)
        end

    elseif keyboard.wasPressed('up') then
        if not self.selected or down then
            self.camera.y = self.camera.y - game.conf.height
            moveBy = game.conf.height
        end

        if self.selected then
            self.selected:setPosition(self.selected.pos.x, self.selected.pos.y - moveBy)
        end

    elseif keyboard.wasPressed('down') then
        if not self.selected or down then
            self.camera.y = self.camera.y + game.conf.height
            moveBy = game.conf.height
        end

        if self.selected then
            self.selected:setPosition(self.selected.pos.x, self.selected.pos.y + moveBy)
        end
    end

    
    -- Reset
    local px, py = mouse.getPosition()
    if not down then

        -- update the selected box
        if self.selected and (self.isMoving or self.isSizing) then
            self.manager:remove(self.selected)
            self.manager:add(self.selected)
        end

        self.hovered = nil
        self.edge = 0
        self.isMoving = false
        self.isSizing = false

        if self.create then
            local x, xs
            if self.mouseOffsetX > px then
                x = px
                xs = self.mouseOffsetX - px
            else
                x = self.mouseOffsetX
                xs = px - self.mouseOffsetX 
            end

            local y, ys
            if self.mouseOffsetY > py then
                y = py
                ys = self.mouseOffsetY - py
            else
                y = self.mouseOffsetY
                ys = py - self.mouseOffsetY 
            end

            self.selected = box.Static(x, y, xs, ys)
            self.isSizing = false
            self.isMoving = false
            self.manager:add(self.selected)
            self.create = false

        end

        self.mouseOffsetX = px
        self.mouseOffsetY = py

    end

    if keyboard.isDown('lshift') and down then
        self.create = true
    end

    -- Hover boxes
    local x, y, mx, my = self.camera.x, self.camera.y, self.camera.x + game.conf.width, self.camera.y + game.conf.height
    local hoveredArea = 100000000000
    self.manager:eachIn(x, y, mx, my, function(box)
        if box:contains(px, py) and self.edge == 0 then

            local area = box.size.x * box.size.y
            if area < hoveredArea then
                self.hovered = box
                hoveredArea = area
            end

        end
    end, true)

    if mouse.wasPressed('l') and self.edge == 0 then
        self.selected = self.hovered
        if self.selected then 
            self.boxOffsetX = px - self.selected.pos.x
            self.boxOffsetY = py - self.selected.pos.y
        end
    end

    -- handle selected boxes
    if self.selected then

        local box = self.selected
        local x, y = box.pos.x, box.pos.y
        local w, h = box.size.x, box.size.y

        local dxl = (x - px)
        local dxr = (x + w - px)
        local dyu = (y - py)
        local dyd = (y + h - py)

        -- resize
        if not self.isMoving and not self.isSizing then
            if dyu >= 2 and dyu <= 8 and dxr > 0 and dxl < 0 then
                self.edge = 1

            elseif dxr <= -2 and dxr >= -8 and dyd > 0 and dyu < 0 then
                self.edge = 2

            elseif dyd <= -2 and dyd >= -8 and dxr > 0 and dxl < 0 then
                self.edge = 4

            elseif dxl >= 2 and dxl <= 8 and dyd > 0 and dyu < 0 then
                self.edge = 8
            end
        end

        if mouse.wasPressed('l') and self.edge ~= 0 then
            self.boxOffsetX = px
            self.boxOffsetY = py
            self.boxBase = {
                x = self.selected.pos.x,
                y = self.selected.pos.y,
                w = self.selected.size.x,
                h = self.selected.size.y
            }
        end

        -- moving
        if down then
            if self.edge == 0 then
                self.selected:setPosition(px - self.boxOffsetX, py - self.boxOffsetY)
                self.isMoving = true

            else

                local dx = px - self.boxOffsetX
                local dy = py - self.boxOffsetY

                if self.edge == 1 then
                    dy = math.min(dy, self.boxBase.h)
                    self.selected:setPosition(self.boxBase.x, self.boxBase.y + dy)
                    self.selected.size.y = math.max(self.boxBase.h - dy, 0)

                elseif self.edge == 2 then
                    self.selected.size.x = math.max(self.boxBase.w + dx, 0)

                elseif self.edge == 4 then
                    self.selected.size.y = math.max(self.boxBase.h + dy, 0)

                elseif self.edge == 8 then
                    dx = math.min(dx, self.boxBase.w)
                    self.selected:setPosition(self.boxBase.x + dx, self.boxBase.y)
                    self.selected.size.x = math.max(self.boxBase.w - dx, 0)
                end

                self.selected:updateBounds()
                self.isSizing = true

            end
        end

        -- toggle blocking directions
        if keyboard.wasPressed('1') then
            if self.selected.blocks.up then
               self.selected.blocks.up = false
            else
               self.selected.blocks.up = true
            end
        end

        if keyboard.wasPressed('2') then
            if self.selected.blocks.right then
               self.selected.blocks.right = false
            else
               self.selected.blocks.right = true
            end
        end

        if keyboard.wasPressed('4') then
            if self.selected.blocks.down then
               self.selected.blocks.down = false
            else
               self.selected.blocks.down = true
            end
        end

        if keyboard.wasPressed('8') then
            if self.selected.blocks.left then
               self.selected.blocks.left = false
            else
               self.selected.blocks.left = true
            end
        end

        -- delete
        if keyboard.wasPressed('delete') then
            self.manager:remove(self.selected)
            self.selected = nil
            self.isSizing = false
            self.isMoving = false
        end

    end

    if keyboard.wasPressed('insert') then
        self.selected = box.Static(px, py, 10, 10)
        self.isSizing = false
        self.isMoving = false
        self.manager:add(self.selected)
    end

    graphics.setRenderOffset(ox, oy)

end


function Editor:render()
    
    local ox, oy = graphics.getRenderOffset()
    graphics.setRenderOffset(-self.camera.x, -self.camera.y)

    local ex, ey = mouse.getPosition()
    if self.hovered then
        local box = self.hovered
        graphics.setColor(0, 255, 0)
        graphics.rect(box.pos.x - 1, box.pos.y - 1, box.size.x + 2, box.size.y + 2)
    end

    if self.selected then

        local box = self.selected
        graphics.setColor(200, 200, 0)
        graphics.rect(box.pos.x - 1, box.pos.y - 1, box.size.x + 2, box.size.y + 2)

        graphics.setColor(0, 0, 200)

        if self.edge == 1 then
            graphics.rect(box.pos.x - 1, box.pos.y - 9, box.size.x + 2, 10)

        elseif self.edge == 4 then
            graphics.rect(box.pos.x - 1, box.pos.y + box.size.y - 1, box.size.x + 2, 10)

        elseif self.edge == 8 then
            graphics.rect(box.pos.x - 9, box.pos.y - 1, 10, box.size.y + 2)

        elseif self.edge == 2 then
            graphics.rect(box.pos.x + box.size.x - 1, box.pos.y - 1, 10, box.size.y + 2)
        end

    end

    if self.create then
        graphics.rect(self.mouseOffsetX, self.mouseOffsetY, ex - self.mouseOffsetX, ey - self.mouseOffsetY)
    end

    -- draw gui
    graphics.setRenderOffset(-self.camera.x, -self.camera.y)

    -- reset offsets
    graphics.setRenderOffset(ox, oy)

end

