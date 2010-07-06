-- LOVE ARCADE BROWSER
-- Author: Shane Gadsby, Luke Perkin and Patrik.
-- Date: 2010-04-02
-- Lists and downloads games from a remote server.


---------------------------
-- LOVE FUNCTIONS
---------------------------
-- Create ArcadeBroswer table to keep everything tidy.
_ArcadeLauncher = {}
function _ArcadeLauncher:load()
	-- Initialization
	function love.load()
		_ArcadeLauncher.oldRequired = {}
		for i,v in pairs(package.loaded) do
			table.insert(_ArcadeLauncher.oldRequired, i)
		end
		-- Load LuaSocket libs.
		require 'socket'
		http = require 'socket.http'
		ltn12 = require 'ltn12'
		-- Load support functions
		require 'inc/supportFunctions'
		-- Load lite version of goo (GUI lib by Luke)
		goo = require 'goo/goo'
		-- Set some variables
		_ArcadeLauncher.folder_name 	= 'loveArcadeLauncher'
		_ArcadeLauncher.server 		= 'localhost'
		_ArcadeLauncher.game_name 	= nil
		_ArcadeLauncher.game_id 	= nil
		_ArcadeLauncher.gameList 	= { {title = 'Loading'} }
		_ArcadeLauncher.total_games	= 0
		_ArcadeLauncher.netSkip		= false
		_ArcadeLauncher.gui			= {}
		-- Set the save folder.
		love.filesystem.setIdentity( _ArcadeLauncher.folder_name )
		-- Initiate the GUI.
		_ArcadeLauncher:initGui( )
		-- Get the list of games.
		_ArcadeLauncher:getGameList( )
	end

	-- Logic
	function love.update(dt)
		goo.update()
	end

	-- Scene Drawing
	function love.draw()
		goo.draw()
		--goo.debugdraw()
	end

	-- Input
	function love.mousepressed(x,y,button)
		goo.mousepressed(x,y,button)
	end

	function love.mousereleased(x,y,button)
	end

	function love.keypressed(key,unicode)
		goo.keypressed(key,unicode)
	end

	function love.keyreleased(key,unicode)
	end
	
	-- Entry point
	function love.run( no_loop )
		if not no_loop then
	    	if love.load then love.load(arg) end
	    	local dt = 0
		end
	    -- Main loop.
	    while true do
	        if love.timer then
	            love.timer.step()
	            dt = love.timer.getDelta()
	        end
			-- will pass 0 if love.timer is disabled
	        if love.update then love.update(dt) end
	        if love.graphics then
	            love.graphics.clear()
	            if love.draw then love.draw() end
	        end
	        -- Process events.
	        if love.event then
	            for e,a,b,c in love.event.poll() do
	                if e == "q" then
	                    if love.audio then
	                        love.audio.stop()
	                    end
	                    return
	                end
	                love.handlers[e](a,b,c)
	            end
	        end
	        if love.timer then love.timer.sleep(1) end
	        if love.graphics then love.graphics.present() end
			if no_loop then break end

	    end
	end
	
	love.load()
end

---------------------------
-- ARCADE BROWSER FUNCTIONS
---------------------------
function _ArcadeLauncher:initGui()
	goo.load()
	-- White background should be nice.
	love.graphics.setBackgroundColor( 255, 255, 255 )
	-- Create table to store the gui objects in.
	self.gui = {}
	-- Create a panel to hold the list of game in.
	local gameList = goo.panel:new( )
	gameList:setPos( 20, 20 )
	gameList:setSize( 110, 350 )
	gameList:setTitle( 'Select a game' )
	gameList:showCloseButton( false )
	self.gui.gameList = gameList
	-- Create a panel to hold the image of the game.
	local gameImage = goo.panel:new( )
	gameImage:setPos( 160, 20 )
	gameImage:setSize( 320, 350 )
	gameImage:setTitle( 'Game preview' )
	gameImage:showCloseButton( false )
	self.gui.gameImage = gameImage
	-- Create the image object.
	local artwork = goo.image:new( gameImage )
	artwork:setPos( 0, 10 )
	artwork:setScale( 0.5 )
	self.gui.artwork = artwork
	-- Create the play button
	local play = goo.button:new( gameImage )
	play:setPos( 100, 320 )
	play:setText( 'Play!' )
	play:sizeToText( )
	play.onClick = _ArcadeLauncher.onCickPlay
end

function _ArcadeLauncher.onCickPlay( button )
	-- Get the name of the selected game.
	local gamename = _ArcadeLauncher.game_name
	local gamedir = _ArcadeLauncher.game_id
	-- Check if it already exists.
	if love.filesystem.exists( gamedir ) then
		_ArcadeLauncher:playGame( gamedir )
		return true
	end
	-- Else download the game
	_ArcadeLauncher:downloadGame( gamedir )
	return true
end

function _ArcadeLauncher:addGameButtons( gamelist )
	local buttonList = {}
	local button, artwork
	for i,v in ipairs(gamelist) do
		artwork = self:getArtwork( v.artwork, v.id )
		buttonList[i] = self:addGameButton( v.title, artwork, 15+(i-1)*25,v.id )
	end
	buttonList[1]:onClick()
end

function _ArcadeLauncher:addGameButton( name, artwork, y, id )
	local button = goo.button:new( self.gui.gameList )
	button:setPos( -3, y )
	button:setSize( 118, 20 )
	button:setText( name )
	button.game_name = name
	button.game_dir = id
	button.artwork = artwork
	button.artworkScale = getScale( artwork, {width=320,height=300})
	function button.onClick( button )
		self.gui.artwork:setImage( button.artwork )
		self.gui.artwork:setScale( button.artworkScale.x, button.artworkScale.y )
		self.gui.gameImage:setTitle( button.game_name )
		self.game_name = button.game_name
		self.game_id = button.game_dir
	end
	return button
end

function _ArcadeLauncher:getGameList()
	if not self.netSkip then
		self.netSkip = true
		local filename = 'gameList.lua'
		local url = string.format( 'http://%s/index.php?content=getProjects&order=id', self.server )
		local new_file = love.filesystem.newFile( filename )
		new_file:open('w')
		local lsink = ltn12.sink.file( new_file )
		local f, e, h = http.request{
			url = url,
			sink = lsink,
			step = self.filePump
		}
		new_file:close() 
		if love.filesystem.exists( filename ) then
			love.filesystem.load( filename )()
			self:addGameButtons( gameList )
		end
		netSkip = false
	end
end

function _ArcadeLauncher:getArtwork( imagename, title )
	if imagename then
			 url = string.format( 'http://%s/projects/%s/%s', self.server, title, imagename )
		else
			url = string.format( 'http://%s/system/img/love1.png',self.server )
			imagename = title..'.png';
	end
	-- Create the artwork directory if it doesn't exist.
		if not love.filesystem.exists('artwork') then
			love.filesystem.mkdir('artwork')
		end
		-- Set the filename
local filename = string.format( 'artwork/%s_%s', title, imagename )
		if love.filesystem.exists( filename )then
			-- File already exists so don't download it.
			return love.graphics.newImage( filename )
		else
			-- File doesn't exist so download it.

			local new_file = love.filesystem.newFile( filename )
			new_file:open('w')
			self.netSkip = true
			local lsink = ltn12.sink.file( new_file )
			local f, e, h = http.request{
				url = url,
				sink = lsink,
				step = self.filePump
			}
			new_file:close() 
			self.netSkip = false
			return love.graphics.newImage( filename )
		end

end

function _ArcadeLauncher:getFileList( gamename )
	-- Create the game directory if it does not exist.
	if not love.filesystem.exists( gamename ) then
		love.filesystem.mkdir( gamename )
	end
	-- Download the list of files.
	local url  = string.format( 'http://%s/index.php?content=fileList&project=%s', self.server, gamename )
	return self:downloadFile( url, gamename..'/.fileList.lua' )
end

function _ArcadeLauncher:downloadGame( gamename )
	-- Show the download progress.
	self.gui.gameList:setVisible( false )
	self.gui.gameImage:setVisible( false )
	
	-- Get a list of all the files we need to download
	-- Note: this could be obsolete when archives are supoorted.
	local file, filename = self:getFileList( gamename )
	if not file then
		return error('.fileList.lua does not exist')
	end
	love.filesystem.load( filename )()
	
	-- Create progress bar
	local progressBar = goo.progressbar:new()
	progressBar:setPos( 55, 240 )
	progressBar:setSize( 0, 29 )
	progressBar:setMaxWidth( 395 )
	progressBar:setRange( 0, #list )
	
	local progressImage = goo.image:new( progressBar )
	progressImage:loadImage( 'img/bar.png' )
	progressImage:setPos(-65,-190)
	
	-- Iterate through each file and download.
	local urlpattern = 'http://%s/projects/%s/%s'
	local url, saveto
	for i,v in ipairs(list) do
		-- Make the directory if it does not exist.
		if not love.filesystem.exists( v.saveFolder ) then
			love.filesystem.mkdir( v.saveFolder )
		end
		url = urlpattern:format( self.server, v.saveFolder, v.file )
		saveto = string.format( '%s/%s', v.saveFolder, v.file )
		self:downloadFile( url, saveto )
		progressBar:increaseProgress()
	end
	self:playGame( gamename )
end

function _ArcadeLauncher:downloadFile( url, saveto, step )
	local step = step or self.filePump
	local new_file = love.filesystem.newFile( saveto )
	new_file:open( 'w' )
	local lsink = ltn12.sink.file( new_file )
	local f, e, h = http.request {
		url = url,
		sink = lsink,
		step = step
	}
	new_file:close( )
	return new_file, saveto
end

function _ArcadeLauncher.filePump( source, sink )
	love.run( true )
	local chunk, src_err = source()
	local ret, snk_err = sink(chunk, src_err)
	return chunk and ret and not src_err and not snk_err, src_err or snk_err
end

function _ArcadeLauncher:playGame( gamename )
	-- Clear the screen
	love.graphics.setBackgroundColor(0,0,0)
	love.graphics.clear()
	-- Set the package path so the game can load file's properly.
	local savedir = love.filesystem.getSaveDirectory()
	local gamedir = string.format( '%s/',  gamename )
	package.path = string.format( '%s/%s/?.lua', savedir, gamename )
	love.filesystem.setIdentity( self.folder_name..'/'..gamedir )
	self:clearModules()
	-- Load the game!
	if love.filesystem.exists( gamedir..'main.lua' ) then
		local game = love.filesystem.load( gamedir..'main.lua' )
		if not game then
			return error('Could not load main.lua')
		end
		-- Load the config.
		local t = self:generateConfig()
		if love.filesystem.exists( gamedir..'conf.lua' ) then
			love.filesystem.load( gamedir..'conf.lua' )()
			love.conf(t)
		end
		-- Set the config.
		love.graphics.setMode(t.screen.width, t.screen.height, t.screen.fullscreen, t.screen.vsync, t.screen.fsaa)
		love.graphics.setCaption(t.title)
		
		-- Unload the Arcade Browser functions.
		self:unload()
		_ArcadeLauncher:changeFilesystem( gamename )
		
		-- Clear out old events before starting the game.
		if love.event then
			for e,a,b,c in love.event.poll() do
			end
		end
		-- LOAD THE GAME.
		game()
		if love.load then love.load() end
		
		-- Allow us to go back.
		-- Currently does not work.
		--_ArcadeLauncher:hook( )
		
		return true
	else
		return error('main.lua does not exist.')
	end
end

function _ArcadeLauncher:unload()
	-- Unload love functions.
	love.load 			= nil
	love.update 		= nil
	love.draw 			= nil
	love.mousepressed 	= nil
	love.mousereleased 	= nil
	love.keypressed 	= nil
	love.keyreleased 	= nil
	-- Destroy the _ArcadeLauncher table.
	goo 						= nil
	_ArcadeLauncher.folder_name 	= nil
	_ArcadeLauncher.server 		= nil
	_ArcadeLauncher.gameList 	= nil
	_ArcadeLauncher.game_name 	= nil
	_ArcadeLauncher.game_id 	= nil
	_ArcadeLauncher.total_games	= nil
	_ArcadeLauncher.netSkip		= nil
	_ArcadeLauncher.gui			= nil
	_ArcadeLauncher.changedFS	= nil
	http						= nil
	ltn12						= nil
	list						= nil
	gameList					= nil
	-- Collect garbage.
	collectgarbage()
	return
end

-- Allow us to go back.
-- Currently does not work.
function _ArcadeLauncher:hook()
	local keyreleased = love.keyreleased
	love.keyreleased = function(key,unicode)
		if key == 'f12' then
			_ArcadeLauncher:unload()
			_ArcadeLauncher:reloadFilesystem()
			_ArcadeLauncher:load()
			love.graphics.setMode(500,400,false)
			love.graphics.setCaption( 'Love Arcade Browser' )
			return false
		else
			if keyreleased then keyreleased(key,unicode) end
		end
	end
end

---------------------
---- Default config.
---------------------
function _ArcadeLauncher:generateConfig()
	local t = {
		console = false,
		title = "Untitled",
		author = "Unnamed",
		version = 0
	}
	t.modules = {
		joystick = true,
		audio = true,
		keyboard = true,
		event = true,
		image = true,
		graphics = true,
		timer = true,
		mouse = true,
		sound = true,
		physics = true
	}
	t.screen = {
		fullscreen = false,
		vsync = true,
		fsaa = 0,
		height = 600,
		width = 800
	}
	return t
end


function _ArcadeLauncher:changeFilesystem( gamename )
	-- Only run this function once.
	if self.changedFS then return end
	self.changedFS = true
	
	-- Make the game directory
	love.filesystem.mkdir( '_SaveFolder/'..gamename )
	
	local functionList = {"enumerate", "exists", "isDirectory", "isFile", "lines", "load", "read"}
	self.filesystem = {}
	
	local dir = string.format( '_SaveFolder/%s/', gamename )
	local _func
	for i,v in ipairs(functionList) do
		self.filesystem[v] = love.filesystem[v]
		if v == 'enumerate' then
			love.filesystem[v]  = function( a, ... )
				local t = self.filesystem[v]( a )
				if self.filesystem[v]( dir .. a ) then
					for i2,v2 in ipairs( self.filesystem[v]( dir .. a, ... ) ) do
						t[#t+1] = v2
					end
				end
				return t
			end
		elseif v == 'exists' then
			love.filesystem[v]  = function( a, ... )
				if ... == true then
					return self.filesystem[v](a)
				else
					if self.filesystem.exists( dir .. a ) then
						return self.filesystem[v]( dir .. a, ...)
					else
						return self.filesystem[v](a, ...)
					end
				end
			end
		else
			love.filesystem[v] = function( a, ... )
				if self.filesystem.exists( dir .. a ) then
					return self.filesystem[v]( dir .. a )
				else
					return self.filesystem[v]( a )
				end
			end
		end
	end
	
	functionList = {"newFile", "mkdir", "write", "remove"}
	for i,v in ipairs(functionList) do
		self.filesystem[v] = love.filesystem[v]
		if v == 'newFile' then
			love.filesystem[v] = function( a, ... )
				if self.filesystem.exists(a, true) then
					return self.filesystem[v]( a, ... )
				else
					return self.filesystem[v]( dir .. a, ... )
				end
			end
		else
			love.filesystem[v] = function( a, ... )
				return self.filesystem[v]( dir .. a, ... )
			end
		end
	end
	
	self.filesystem.setIdentity = love.filesystem.setIdentity
	love.filesystem.setIdentity = function() end
end

function _ArcadeLauncher:reloadFilesystem()
	for k,v in pairs( self.filesystem ) do
		love.filesystem[k] = v
	end
end

function _ArcadeLauncher:clearModules()
	for i,v in pairs(package.loaded) do
		local wasLoaded = false
		for j,b in pairs(self.oldRequired) do
			if i == b then
				wasLoaded = true
			end
		end
		if not wasLoaded then
			package.loaded[i] = nil
		end
	end
end



---------------------
---- Load me.
---------------------
function love.load()
	_ArcadeLauncher:load()
end

