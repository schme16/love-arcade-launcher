-- Filename: goo.lua
-- Author: Luke Perkin
-- Date: 2010-02-25

require 'goo/MiddleClass'
require 'goo/MindState'

-- Initialization
local goo = {}

goo.skin = 'goo/skins/default/'
goo.style, goo.fonts = require( goo.skin .. 'style')

goo.base = class('goo')
function goo.base:initialize()
	self.visible = true
	self.parent = self
	self.children = {}
	self.x, self.y = 0, 0
	self.mousehover = self
end
function goo.base:update() self.mousehover = self end
function goo.base:draw() end
function goo.base:getRelativePos() return 0,0 end
function goo.base:mousepressed() end
function goo.base:mousereleased() end
function goo.base:keypressed() end
function goo.base:keyreleased() end

goo.object = class('goo object')
goo.objects = {}
function goo.object:initialize(parent)
	--table.insert(goo.objects, self)
	if parent then
		table.insert(parent.children,self)
		self.parent = parent
	else
		table.insert( goo.BASEOBJECT.children, self )
		self.parent = goo.BASEOBJECT
	end
	if goo.style[self.class.name] then
		self.style = goo.style[self.class.name]
	end
	self.x = 0
	self.y = 0
	self.h = 0
	self.w = 0
	self.lastX = 0
	self.lastY = 0
	self.bounds = {x1=0,y1=0,x2=0,y2=0}
	self.color  = {255,255,255,255}
	self.children = {}
	self.visible = true
	self.hoverState = true
end
function goo.object:destroy()
	if self.parent then
		for k,v in pairs(self.parent.children) do
			if v == self then table.remove(self.parent.children,k) end
		end
	end
	for i,child in ipairs(self.children) do
		child:destroy()
	end
	self = nil
	return
end
function goo.object:update(dt)
	if self:isMouseHover() then
		if not self.hoverState then self:enterHover() end
		self.hoverState = true
		goo.BASEOBJECT.mousehover = self
	else
		if self.hoverState then self:exitHover() end
		self.hoverState = false
	end
	
	if love.mouse.isDown('l') then
		-- Left mouse button pressed
	else
		if self.dragState then
			self.dragState = false
			self:recurse('children', self.updateBounds)
		end
	end
	
	if self.x ~= self.lastX or self.y ~= self.lastY then
		self:updateBounds()
	end
	
	self.lastX = self.x
	self.lastY = self.y
end
function goo.object:draw(x,y) end
function goo.object:mousepressed() end
function goo.object:mousereleased(x,y,button)
	if self.hoverState and button == 'l' then
		if self.onClick then
			self:onClick()
		end
	end
end
function goo.object:keypressed() end
function goo.object:keyreleased() end
function goo.object:setPos( x, y )
	self.x = x or 0
	self.y = y or 0
	self:updateBounds()
end
function goo.object:setSize( w, h )
	self.w = w or self.w
	self.h = h or self.h
	self:updateBounds()
end
function goo.object:setVisible( bool )
	self.visible = bool
end
function goo.object:setColor(r,g,b,a)
	self.color = {r or self.color[1], g or self.color[2], b or self.color[3], a or self.color[4]}
end
function goo.object:getRelativePos( x, y )
	local _x, _y
	local x, y = self.x or x, self.y or y
	if self.parent then
		_x, _y = self.parent:getRelativePos()
	else
		_x, _y = 0, 0
	end
	return _x+x, _y+y
end
function goo.object:isMouseHover()
	if not self.bounds then return false end
	local x, y = love.mouse.getPosition()
	local x1, y1, x2, y2 = self.bounds.x1, self.bounds.y1, self.bounds.x2, self.bounds.y2
	if x > x1 and x < x2 and y > y1 and y < y2 then
		return true
	else
		return false
	end
end
function goo.object:enterHover() end
function goo.object:exitHover() end
function goo.object:updateBounds()
	local x, y = self:getRelativePos()
	local xoff, yoff = self.xoffset or 0, self.yoffset or 0
	self.bounds.x1 = x + xoff
	self.bounds.y1 = y + yoff
	self.bounds.x2 = x + self.w + xoff
	self.bounds.y2 = y + self.h + yoff
end
function goo.object:recurse(key,func,...)
	local _tbl = arg or {}
	func(self, ...)
	for k,v in pairs(self.children) do
		v:recurse(key,func,...)
	end
end
function goo.object:setText( text )
	self.text = text
	self:updateBounds()
end
function goo.object:sizeToContents()
	local _font = love.graphics.getFont()
	self.w = _font:getWidth(self.text) + (self.spacing or 0)
	self.h = _font:getHeight() + (self.spacing or 0)
	self.yoffset = -self.h
	self:updateBounds()
end
function goo.object:setStyle(style)
	if type(style) == 'table' then
		for k,v in pairs(style) do
			self.style[k] = v
		end
		return true
	elseif type(style) == 'string' then
		for k,v in pairs(goo.style[style]) do
			self.style[k] = v
		end
		return true
	end
	return false
end
-- Resets the style.
function goo.object:resetStyle()
	self.style = goo.style[self.class.name]
end

-- NULL OBJECT
goo.null = class('goo null', goo.object)
function goo.null:initialize( parent )
	super.initialize(self,parent)
end

-- IMAGE OBJECT
goo.image = class('goo image', goo.object)
function goo.image:initialize( parent )
	super.initialize(self,parent)
	self.image = nil
	self.rotation = 0
	self.xscale = 1
	self.yscale = 1
end
function goo.image:setImage( image )
	self.image = image
end
function goo.image:loadImage( imagename )
	self.image = love.graphics.newImage( imagename )
end
function goo.image:draw( x, y )
	if self.image then
		love.graphics.setColor(255,255,255,255)
		love.graphics.draw( self.image, x, y, self.rotation, self.xscale, self.yscale )
	end
end
function goo.image:setScale( x, y )
	self.xscale = x or 1
	self.yscale = y or self.xscale
end

-- PANEL
goo.panel = class('goo panel', goo.object)
goo.panel.image = {}
goo.panel.image.corner = love.graphics.newImage(goo.skin..'box_corner.png')
goo.panel.image.edge = love.graphics.newImage(goo.skin..'box_edge.png')
function goo.panel:initialize(parent)
	super.initialize(self,parent)
	self.title = "title"
	self.close = goo.close:new(self)
	self.dragState = false
	self.canDrag = false
end
function goo.panel:update(dt)
	super.update(self,dt)
	if self.dragState then
		self.x = love.mouse.getX() - self.dragOffsetX
		self.y = love.mouse.getY() - self.dragOffsetY
		self:updateBounds()
	end
end
function goo.panel:drawbox(x,y)
	local cornerH = self.image.corner:getHeight()
	local cornerW = self.image.corner:getWidth()
	local edgeH	  = self.image.edge:getHeight()
	local edgeW	  = self.image.edge:getWidth()
	love.graphics.setColor( unpack(self.style.borderColor) )
	love.graphics.draw( self.image.corner, x-cornerH, y-cornerH )
	love.graphics.draw( self.image.corner, x+self.w+cornerH, y-cornerH, math.pi/2 )
	love.graphics.draw( self.image.corner, x+self.w+cornerH, y+self.h+cornerH, math.pi )
	love.graphics.draw( self.image.corner, x-cornerH, y+self.h+cornerH, 3*math.pi/2 )
	
	love.graphics.draw( self.image.edge, x, y-edgeH, 0, self.w, 1)
	love.graphics.draw( self.image.edge, x+self.w+edgeH, y, math.pi/2, self.h, 1)
	love.graphics.draw( self.image.edge, x+self.w, y+self.h+edgeH, math.pi, self.w, 1)
	love.graphics.draw( self.image.edge, x-edgeH, y+self.h, 3*math.pi/2, self.h, 1)
	
	love.graphics.setColor( unpack(self.style.backgroundColor) )
	love.graphics.rectangle('fill', x, y, self.w, self.h)
end
function goo.panel:draw( x, y )
	super.draw(x,y)
	self:drawbox(x,y)
	love.graphics.setColor( unpack(self.style.seperatorColor) )
	love.graphics.setLine(1, 'smooth')
	love.graphics.line( x, y+8, x + self.w, y+8)
	love.graphics.setColor( unpack(self.style.titleColor) )
	love.graphics.setFont( self.style.titleFont )
	love.graphics.print( self.title, x, y + 5)
end
function goo.panel:mousepressed(x,y,button)
	if not self.canDrag then return false end
	if x > self.bounds.x1 and x < self.bounds.x2 and y > self.bounds.y1 and y < self.bounds.y2 then
		if not self.dragState then
			self.dragOffsetX = x - self.x
			self.dragOffsetY = y - self.y
		end
		self.dragState = true
	end
end
function goo.panel:mousereleased(x,y,button)
end
function goo.panel:setTitle( title )
	self.title = title
end
function goo.panel:setPos( x, y )
	super.setPos(self, x, y)
	self:setClosePos()
	self:updateBounds()
end
function goo.panel:setSize( w, h )
	super.setSize(self, w, h)
	self:setClosePos()
	self:updateBounds()
end
function goo.panel:setClosePos()
	local a = self.image.edge:getHeight()/2
	self.close:setPos( self.w - 4, -a + 2 )
end
function goo.panel:showCloseButton( bool )
	self.close.visible = bool
end
function goo.panel:setCanDrag( bool )
	self.canDrag = bool
end
function goo.panel:updateBounds()
	local edgeH	  = goo.panel.image.edge:getHeight()/2
	local x, y = self:getRelativePos()
	self.bounds.x1 = x - edgeH
	self.bounds.y1 = y - edgeH
	self.bounds.x2 = x + self.w + edgeH
	self.bounds.y2 = y + self.h + edgeH
end
function goo.panel:destroy()
	for k,v in pairs(self.children) do
		v:destroy()
	end
	super.destroy(self)
end

-- STATIC TEXT
goo.text = class('goo static text', goo.object)
function goo.text:initialize( parent )
	super.initialize(self,parent)
	self.text = "no text"
end
function goo.text:draw(x,y)
	love.graphics.setColor( unpack(self.color) )
	love.graphics.print( self.text, x, y )
end
function goo.text:setText( text )
	self.text = text or ""
end

-- CLOSE BUTTON
goo.close = class('goo close button', goo.object)
goo.close.image = {}
goo.close.image.button = love.graphics.newImage(goo.skin..'closebutton.png')
function goo.close:initialize( parent )
	super.initialize(self,parent)
	self.w = self.image.button:getWidth()
	self.h = self.image.button:getHeight()
end
function goo.close:enterHover()
	self.color = {255,200,200,255}
end
function goo.close:exitHover()
	self.color = {255,255,255,255}
end
function goo.close:draw( x, y )
	love.graphics.setColor( unpack(self.color) )
	love.graphics.draw(self.image.button,x,y)
end
function goo.close:mousepressed(x,y,button)
	if button == 'l' then self.parent:destroy() end
end

-- BUTTON
goo.button = class('goo button', goo.object)
function goo.button:initialize( parent )
	super.initialize(self,parent)
	self.text = "button"
	self.borderStyle = 'line'
	self.backgroundColor = {0,0,0,255}
	self.borderColor = {255,255,255,255}
	self.textColor = {255,255,255,255}
	self.spacing = 5
	self.border = true
	self.background = true
end

function goo.button:draw(x,y)
	if self.background then
		love.graphics.setColor( unpack(self.backgroundColor) )
		love.graphics.rectangle( 'fill', x, y, self.w , self.h )
	end
	if self.border then
		love.graphics.setLine( 1, 'rough' )
		love.graphics.setColor( unpack(self.borderColor) )
		love.graphics.rectangle( 'line', x, y, self.w+2, self.h )
	end
	
	love.graphics.setColor( unpack(self.textColor) )
	love.graphics.setFont( self.style.textFont )
	local fontW,fontH = self.style.textFont:getWidth(self.text), self.style.textFont:getHeight()
	local ypos = y+((self.h - fontH)/2)+(fontH*0.8)
	local xpos = x+((self.w - fontW)/2)
	love.graphics.print( self.text, xpos, ypos )
end
function goo.button:enterHover()
	self.backgroundColor = self.style.backgroundColorHover
	self.borderColor = self.style.borderColorHover
	self.textColor = self.style.textColorHover
end
function goo.button:exitHover()
	self.backgroundColor = self.style.backgroundColor
	self.borderColor = self.style.borderColor
	self.textColor = self.style.textColor
end
function goo.button:mousepressed(x,y,button)
	if self.onClick then self:onClick(button) end
end
function goo.button:setText( text )
	self.text = text
end
function goo.button:sizeToText( padding )
	local padding = padding or 5
	local _font = self.style.textFont or love.graphics.getFont()
	self.w = _font:getWidth(self.text) + (padding*2)
	self.h = _font:getHeight()  + (padding*2)
	self:updateBounds()
end
goo.button:getterSetter('border')
goo.button:getterSetter('background')

--  TEXT INPUT
goo.textinput = class('goo text input', goo.object)
function goo.textinput:initialize( parent )
	super.initialize(self,parent)
	self.text = ''
	self.textXoffset = 0
	self.focus = false
	self.blink = false
	self.blinkRate = 0.5
	self.blinkTime = love.timer.getTime() + self.blinkRate
	self.font = love.graphics.getFont()
	self.fontH = self.font:getHeight()
	self.caretPos = 1
	self.lines = {}
	self.lines[1] = ''
	self.linePos = 1
	self.leading = 35
	self.multiline = true
	love.keyboard.setKeyRepeat( 500, 50 )
end
function goo.textinput:update(dt)
	super.update(self,dt)
	if love.timer.getTime() > self.blinkTime then
		self.blink = not self.blink
		self.blinkTime = love.timer.getTime() + self.blinkRate
	end
	if love.mouse.isDown('l') and not self.hoverState then self.focus = false end
	self.textXoffset = self.font:getWidth( self.lines[self.linePos]:sub(1,self.caretPos) ) - self.w + 15
	if self.textXoffset < 0 then self.textXoffset = 0 end
	if self.caretPos < 1 then self.caretPos = 1 end
end
function goo.textinput:draw(x,y)
	if self.style.textFont then
		love.graphics.setFont( self.style.textFont )
	else
		love.graphics.setFont( 12 )
	end
	self.font = love.graphics.getFont()
	self.fontH = self.font:getHeight()

	
	--love.graphics.setLine(1,'rough')
	
	local w = self.style.borderWidth
	
	love.graphics.setColor( unpack(self.style.borderColor) )
	love.graphics.rectangle('fill',x-w,y-w,self.w+(w*2),self.h+(w*2))
	love.graphics.setColor( unpack(self.style.backgroundColor) )
	love.graphics.rectangle('fill',x,y,self.w,self.h)
	love.graphics.setScissor( x, y-1, self.w, self.h+1 )
	
	for i,txt in ipairs(self.lines) do
		love.graphics.setColor( unpack(self.style.textColor) )
		love.graphics.print( txt, x+5-self.textXoffset, (y+self.fontH)+(self.leading*(i-1)))
	end
	if self.blink and self.focus then
		love.graphics.setColor( unpack(self.style.cursorColor) )
		local w = self.font:getWidth( self.lines[self.linePos]:sub(1,self.caretPos-1) )
		w = math.min( w, self.w - 15 )
		love.graphics.rectangle('fill', x+w+5, (y+2)+(self.leading*(self.linePos-1)), self.style.cursorWidth, self.fontH)
	end
	love.graphics.setScissor()
end
function goo.textinput:keypressed(key,unicode)
	if not self.focus then return false end
	if key == 'backspace' then
		self:keyBackspace()
	elseif key == 'return' then
		self:keyReturn()
	elseif key == 'left' then
		self:keyLeft()
	elseif key == 'right' then
		self:keyRight()
	elseif key == 'up' then
		self:keyUp()
	elseif key == 'down' then
		self:keyDown()
	elseif unicode ~= 0 and unicode < 1000 then
		self:keyText(key,unicode)
	end
	return true
end
function goo.textinput:keyText(key,unicode)
	self:insert(string.char(unicode), self.caretPos)
	self.caretPos = self.caretPos + 1
end
function goo.textinput:keyReturn()
	if not self.multiline then return end
	if self.caretPos > self.lines[self.linePos]:len() then
		self.linePos = self.linePos + 1
		self.caretPos = 1
		self:newline( self.linePos )
	else
		self:newlineWithText( self.caretPos, self.linePos )
	end
end
function goo.textinput:keyBackspace()
	if self.caretPos == 1 and self.linePos > 1 then
		if not self.multiline then return end
		self:backspaceLine( self.linePos )
	else
		self:remove(self.caretPos,1)
		self.caretPos = self.caretPos - 1
	end
end
function goo.textinput:keyLeft()
	if self.caretPos > 1 then
		self.caretPos = self.caretPos - 1
		if self.caretPos < 1 then self.caretPos = 1 end
	else
		if self.linePos > 1 then
			if not self.multiline then return end
			self.linePos = self.linePos - 1
			self.caretPos = self.lines[self.linePos]:len()+1
		end
	end
end
function goo.textinput:keyRight()
	if self.caretPos <= self.lines[self.linePos]:len() then
		self.caretPos = self.caretPos + 1
	else
		if not self.multiline then return end
		if self.linePos < #self.lines then
			self.linePos = self.linePos+1
			self.caretPos = 1
		end
	end
end
function goo.textinput:keyUp()
	if not self.multiline then return end
	if self.linePos == 1 then return end
	self.linePos = self.linePos - 1
end
function goo.textinput:keyDown()
	if not self.multiline then return end
	if self.linePos == #self.lines then return end
	self.linePos = self.linePos + 1
end
function goo.textinput:insert(text,pos)
	local txt = self.lines[self.linePos]
	local part1 = txt:sub(1,pos-1)
	local part2 = txt:sub(pos)
	self.lines[self.linePos] = part1 .. text .. part2
end
function goo.textinput:remove(pos,length)
	if pos == 1 then return end
	local txt = self.lines[self.linePos]
	local part1 = txt:sub(1,pos-2)
	local part2 = txt:sub(pos+length-1)
	self.lines[self.linePos] = part1 .. part2
end
function goo.textinput:newline(pos)
	local pos = pos or nil
	table.insert(self.lines,pos,'')
end
function goo.textinput:removeline(pos)
	local pos = pos or #self.lines
	table.remove(self.lines,pos)
end
function goo.textinput:backspaceLine()
	local _line = self.lines[self.linePos]
	self:removeline( self.linePos )
	self.linePos = self.linePos - 1
	self.caretPos = self.lines[self.linePos]:len()+1
	self.lines[self.linePos] = self.lines[self.linePos] .. _line
end
function goo.textinput:newlineWithText(pos,pos2)
	local part1 = self.lines[self.linePos]:sub(1,pos-1)
	local part2 = self.lines[self.linePos]:sub(pos)
	self.lines[pos2] = part1
	self:newline(self.linePos+1)
	self.linePos = self.linePos + 1
	self.caretPos = 1
	self.lines[self.linePos] = part2
end
function goo.textinput:mousepressed( x, y, button )
	self.focus = true
end
function goo.textinput:getText()
	local text = ''
	for i,v in ipairs(self.lines) do
		text = text .. v .. '\n'
	end
	return text
end

-------------------------------------------------------------
------ PROGRESS BAR.
-------------------------------------------------------------
goo.progressbar = class('goo progressbar', goo.object)
function goo.progressbar:initialize( parent )
	super.initialize(self,parent)
	self.current_progress 	= 0
	self.max_progress 		= 100
	self.max_width			= 100
	self.scale				= 100
	self.fill_mode			= 'fill'
	self:setRange()
end
function goo.progressbar:draw( x, y )
	love.graphics.setColor( unpack(self.style.backgroundColor) )
	love.graphics.rectangle( self.fill_mode, x, y, self.width, self.height )
end
function goo.progressbar:setProgress( progress )
	self.current_progress = progress
	local w = self.current_progress/self.range
end
function goo.progressbar:setRange( min, max )
	local min = min or 0
	local max = max or 100
	self.range = (max-min)
end
function goo.progressbar:setSize( w, h )
	local w = w or self.width or 0
	local h = h or self.height or 20
	self.width = w
	self.height = h
end
function goo.progressbar:setMaxWidth( w )
	self.max_width = w
	self.scale = self.range / w
end
function goo.progressbar:increaseProgress()
	self.current_progress = self.current_progress + 1
	self:setSize( (self.current_progress / self.range) * self.max_width )
end


--
--
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- Load
function goo.load()
	goo.graphics = {}
	goo.graphics.roundrect = require 'goo.graphics.roundrect'
	-- Baseobject is the master parent for all objects.
	goo.BASEOBJECT = goo.base:new()
end

-- Logic
function goo.update( dt, object )
	local object = object or goo.BASEOBJECT
	object:update(dt)
	for k,child in pairs(object.children) do
		if child.visible then goo.update(dt,child) end
	end
end

-- Scene Drawing
function goo.draw( object, x, y )
	local object = object or goo.BASEOBJECT
	object:draw( x, y )
	for i,child in ipairs(object.children) do
		x,y = child:getRelativePos()
		if child.visible then goo.draw(child,x,y) end
	end
end

function goo.debugdraw()
	local mx,my = love.mouse.getPosition( )
	local obj = goo.BASEOBJECT.mousehover
	local x,y = obj:getRelativePos()
	local style = goo.style['goo debug']
	
	local offx,offy = 10,10
	if mx > love.graphics.getWidth()-120 then offx = -(offx+100) end
	if my > love.graphics.getHeight()-65 then offy = -(offy+65) end
	
	love.graphics.setFont(style.textFont)
	love.graphics.setColor(unpack(style.backgroundColor))
	love.graphics.rectangle( 'fill', mx+offx-5, my+offy-15, 118,80)
	love.graphics.setColor(unpack(style.textColor))
	love.graphics.print( obj.class.name, mx+offx, my+offy )
	love.graphics.print( 'mouse: '..mx..', '..my, mx+offx, my+offy+20 )
	love.graphics.print( 'position: '..obj.x..', '..obj.y, mx+offx, my+offy+32 )
	love.graphics.print( 'relative: '..mx-x..', '..my-y, mx+offx, my+offy+44 )
	love.graphics.print( 'parent: '..mx-obj.parent.x..', '..my-obj.parent.y, mx+offx, my+offy+56 )
end

-- Input
function goo.keypressed( key, unicode, object )
	local object = object or goo.BASEOBJECT
	local ret = false
	if object.visible then ret = object:keypressed(key, unicode) end
	for i,child in ipairs(object.children) do
		ret = goo.keypressed(key, unicode, child)
	end
	return ret
end

function goo.keyreleased( key, unicode, object )
	local object = object or goo.BASEOBJECT
	if object.visible then ret = object:keyreleased(key, unicode) end
	for i,child in ipairs(object.children) do
		local ret = goo.keyreleased(key, unicode, child)
	end
	return ret
end

function goo.mousepressed( x, y, button )
	local object = goo.BASEOBJECT.mousehover
	if object.visible then object:mousepressed( x, y, button ) end
end

function goo.mousereleased( x, y, button )
	local object = goo.BASEOBJECT.mousehover
	if object.visible then object:mousereleased( x, y, button ) end
end

return goo