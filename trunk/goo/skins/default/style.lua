-- Filename: goo.lua
-- Author: Luke Perkin
-- Date: 2010-02-26
-- Returns Style, Fonts.

local style = {}
local fonts = {}
fonts.default12 = love.graphics.newFont(12)
fonts.default24 = love.graphics.newFont(24)
fonts.oldsans12 = love.graphics.newFont('fonts/PinstripeLimo.ttf')
fonts.oldsans24 = love.graphics.newFont('fonts/PinstripeLimo.ttf',24)
fonts.oldsans32 = love.graphics.newFont('fonts/PinstripeLimo.ttf',32)

style['goo panel'] = {
	backgroundColor = {255,255,255,255},
	borderColor = {255,255,255,255},
	titleColor = {130,130,130,255},
	titleFont = fonts.default12,
	seperatorColor = {100,100,100,255}
}

style['goo button'] = {
	backgroundColor = {100,100,100,0},
	backgroundColorHover = {131,203,21,255},
	borderColor = {0,0,0,0},
	borderColorHover = {0,0,0,0},
	textColor = {0,0,0,255},
	textColorHover = {0,0,0,255},
	textFont = fonts.default12
}

style['goo progressbar'] = {
	backgroundColor = { 255, 109, 190, 255 }
}

style['goo text input'] = {
	borderColor = {0,0,0,255},
	backgroundColor = {255,255,255,255},
	textColor = {255,0,0,255},
	cursorColor = {0,0,0,255},
	cursorWidth = 2,
	borderWidth = 2,
	textFont = fonts.oldsans12,
	lineHeight = 1
}

style['goo debug'] = {
	backgroundColor = {0,0,0,170},
	textColor = {255,255,255,255},
	textFont = fonts.oldsans12
}

return style, fonts

