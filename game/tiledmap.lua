-- loader for "tiled" map editor maps (.tmx,xml-based) http://www.mapeditor.org/
-- supports multiple layers
-- NOTE : function ReplaceMapTileClass (tx,ty,oldTileType,newTileType,fun_callback) end
-- NOTE : function TransmuteMap (from_to_table) end -- from_to_table[old]=new
-- NOTE : function GetMousePosOnMap () return gMouseX+gCamX-gScreenW/2,gMouseY+gCamY-gScreenH/2 end

kTileSize = 32
kMapTileTypeEmpty = 0
local floor = math.floor
local ceil = math.ceil

function TiledMap_Load (filepath,tilesize,spritepath_removeold,spritepath_prefix)
	spritepath_removeold = spritepath_removeold or "../"
	spritepath_prefix = spritepath_prefix or ""
	kTileSize = tilesize or 32
	gTileGfx = {}
	
	local tiletype,layers = TiledMap_Parse(filepath)
	gMapLayers = layers
	--print("gMapLayers length: "..table.getn(layers).." tiles: "..table.getn(tiletype.tile))
	for first_gid,path in pairs(tiletype) do 
		path = spritepath_prefix .. string.gsub(path,"^"..string.gsub(spritepath_removeold,"%.","%%."),"")
		--local raw = love.image.newImageData(path) --THIS CREATES A NEW IMAGE OBJECT (CAN'T BE DRAWN DIRECTLY ON SCREEN)
--[[CHANGED]]		local raw = gfx.loadpng(path) -- CREATES A NEW IMAGE OF HERO AND FLOOR IMAGE FILE
		--local w,h = raw:getWidth(),raw:getHeight()
--[[CHANGED]]		local w,h = raw:get_width(), raw:get_height() 
		local gid = first_gid
		local e = kTileSize
--[[CHANGED]]	local sprite = gfx.new_surface(kTileSize,kTileSize)
				--sprite:paste(raw,0,0,x*e,y*e,e,e)
--[[CHANGED]]	sprite:copyfrom(raw,nil,nil,true) -- PUTS THE CREATED IMAGE (RAW) ON THE SPRITE SURFACE AND SETS ITS SEIZE TO e
				--gTileGfx[gid] = love.graphics.newImage(sprite)
--[[CHANGED]]	gTileGfx[gid] = sprite
--[[CHANGED]]	--sprite:destroy() -- DESTROYS THE SPRITE SURFACE TO SAVE RAM
				gid = gid + 1
--[[		for y=0,floor(h/kTileSize)-1 do -- I WONDER WHAT THIS DOES??
			for x=0,floor(w/kTileSize)-1 do -- I WONDER WHAT THIS DOES??
				--local sprite = love.image.newImageData(kTileSize,kTileSize) -- THIS CREATES A NEW IMAGE DATA OBJECT (ALL BLACK)
	CHANGED		local sprite = gfx.new_surface(kTileSize,kTileSize)
				--sprite:paste(raw,0,0,x*e,y*e,e,e)
	CHANGED		sprite:copyfrom(raw,nil,nil,true) -- PUTS THE CREATED IMAGE (RAW) ON THE SPRITE SURFACE AND SETS ITS SEIZE TO e
				--gTileGfx[gid] = love.graphics.newImage(sprite)
	CHANGED		gTileGfx[gid] = sprite
	CHANGED		sprite:destroy() -- DESTROYS THE SPRITE SURFACE TO SAVE RAM
				gid = gid + 1
			end
		end
]]
--[[CHANGED]]	raw:destroy() -- DESTROYS THE RAW IMAGE TO SAVE RAM
	end
end

function TiledMap_GetMapTile (tx,ty,layerid) -- coords in tiles
	local row = gMapLayers[layerid][ty]
	return row and row[tx] or kMapTileTypeEmpty
end

function TiledMap_DrawNearCam (camx,camy) -- camx AND camy SEEMS TO BE THE COORDINATES OF THE CHARACTER OBJECTS TOP LEFT CORNER
	camx,camy = floor(camx),floor(camy)
	local screen_w = screen:get_width()
	local screen_h = screen:get_height()
	local minx,maxx = floor((camx-screen_w/2)/kTileSize),ceil((camx+screen_w/2)/kTileSize) -- WHAT DO THIS DO?
	local miny,maxy = floor((camy-screen_h/2)/kTileSize),ceil((camy+screen_h/2)/kTileSize) -- WHAT DO THIS DO?
	for tileId = 1,#gMapLayers do -- DOES THIS SET THE POSITION OF THE TILES??
		for x = minx,maxx do -- DOES THIS SET THE POSITION OF THE TILES??
			for y = miny,maxy do -- DOES THIS SET THE POSITION OF THE TILES??
				local gfx = gTileGfx[TiledMap_GetMapTile(x,y,tileId)]
				if (gfx) then
					local sx = x*kTileSize - camx + screen_w/2 -- WHAT DOES THIS DO?
					local sy = y*kTileSize - camy + screen_h/2 -- WHAT DOES THIS DO?
					--love.graphics.draw(gfx,sx,sy) -- x, y, r, sx, sy, ox, oy
--[[CHANGED]]		screen:copyfrom(gfx,nil,{x=sx,y=sy,nil,nil})
				end
			end
		end
	end
end


-- ***** ***** ***** ***** ***** xml parser


-- LoadXML from http://lua-users.org/wiki/LuaXml
function LoadXML(s)
  local function LoadXML_parseargs(s)
    local arg = {}
    string.gsub(s, "(%w+)=([\"'])(.-)%2", function (w, _, a)
  	arg[w] = a
    end)
    return arg
  end
  local stack = {}
  local top = {}
  table.insert(stack, top)
  local ni,c,label,xarg, empty
  local i, j = 1, 1
  while true do
    ni,j,c,label,xarg, empty = string.find(s, "<(%/?)([%w:]+)(.-)(%/?)>", i)
    if not ni then break end
    local text = string.sub(s, i, ni-1)
    if not string.find(text, "^%s*$") then
      table.insert(top, text)
    end
    if empty == "/" then  -- empty element tag
      table.insert(top, {label=label, xarg=LoadXML_parseargs(xarg), empty=1})
    elseif c == "" then   -- start tag
      top = {label=label, xarg=LoadXML_parseargs(xarg)}
      table.insert(stack, top)   -- new level
    else  -- end tag
      local toclose = table.remove(stack)  -- remove top
      top = stack[#stack]
      if #stack < 1 then
        error("nothing to close with "..label)
      end
      if toclose.label ~= label then
        error("trying to close "..toclose.label.." with "..label)
      end
      table.insert(top, toclose)
    end
    i = j+1
  end
  local text = string.sub(s, i)
  if not string.find(text, "^%s*$") then
    table.insert(stack[#stack], text)
  end
  if #stack > 1 then
    error("unclosed "..stack[stack.n].label)
  end
  return stack[1]
end


-- ***** ***** ***** ***** ***** parsing the tilemap xml file

local function getTilesets(node)
	local tiles = {}
	for k, sub in ipairs(node) do
		if (sub.label == "tileset") then
			tiles[tonumber(sub.xarg.firstgid)] = sub[1].xarg.source
		end
	end
	return tiles
end

local function getLayers(node)
	local layers = {}
	for k, sub in ipairs(node) do
		if (sub.label == "layer") then --  and sub.xarg.name == layer_name
			local layer = {}
			table.insert(layers,layer)
			width = tonumber(sub.xarg.width)
			i = 1
			j = 1
			for l, child in ipairs(sub[1]) do
				if (j == 1) then
					layer[i] = {}
				end
				layer[i][j] = tonumber(child.xarg.gid)
				j = j + 1
				if j > width then
					j = 1
					i = i + 1
				end
			end
		end
	end
	return layers
end

function TiledMap_Parse(filename)
	local xml = LoadXML(love.filesystem.read(filename))
	local tiles = getTilesets(xml[2])
	local layers = getLayers(xml[2])
	return tiles, layers
end

-- basic check collision - logic
function hitTest (camx, camy, herox, heroy, herosize)
	camx,camy = floor(camx),floor(camy)
	local screen_w = love.graphics.getWidth()
	local screen_h = love.graphics.getHeight()
	local minx,maxx = floor((camx-screen_w/2)/kTileSize),ceil((camx+screen_w/2)/kTileSize)
	local miny,maxy = floor((camy-screen_h/2)/kTileSize),ceil((camy+screen_h/2)/kTileSize)
	for layerId = 1,#gMapLayers do
	    for x = minx,maxx do
		      for y = miny,maxy do
		        local gfx = gTileGfx[TiledMap_GetMapTile(x,y,layerId)]
		        if (gfx) then
		          local sx = x*kTileSize - camx + screen_w/2
		          local sy = y*kTileSize - camy + screen_h/2
		          local temp = CheckCollision2(herox, heroy, herosize, herosize, sx, sy, kTileSize, kTileSize)
		          if temp ~= nil then
		              return temp
		          end
		    --			love.graphics.draw(gfx,sx,sy) -- x, y, r, sx, sy, ox, oy
		        end
		      end
	    end
	end
  return nil
end

-- basic check collesion
function checkCollesion(ax1,ay1,aw,ah, bx1,by1,bw,bh)
  local ax2,ay2,bx2,by2 = ax1 + aw, ay1 + ah, bx1 + bw, by1 + bh
  if ax1 < bx2 and ax2 > bx1 and ay1 < by2 and ay2 > by1 then
    return 1-- left & right
  end
  return 0
end
