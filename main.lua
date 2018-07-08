
local lstSprites = {}

local theHuman = {}

local theZombie = {}

local ZSTATES = {}
ZSTATES.NONE = ""
ZSTATES.WALK = "walk"
ZSTATES.ATTACK = "attack"
ZSTATES.BITE = "bite"
ZSTATES.CHANGEDIR = "change"

local imgAlert = love.graphics.newImage("images/alert.png")

-- Import a dynamic light library
local LightWorld = require("shadows.LightWorld")
local Light = require("shadows.Light")

-- Create a light world
newLightWorld = LightWorld:new()

-- Display the game menu
current_screen = "menu"

-- Returns the distance between two points.
function math.dist(x1,y1, x2,y2) return ((x2-x1)^2+(y2-y1)^2)^0.5 end

-- Returns the angle between two points.
function math.angle(x1,y1, x2,y2) return math.atan2(y2-y1, x2-x1) end

function CreateSprite(pList, pType, psImageFile, pnFrames)
  
  local mySprite = {}
  mySprite.type = pType
  mySprite.visible = true
  
  mySprite.images = {}
  mySprite.currentFrame = 0
  local i
  for i=0,pnFrames do
    local fileName = "images/"..psImageFile..tostring(i)..".png"
    mySprite.images[i] = love.graphics.newImage(fileName)
  end
  
  mySprite.x = 0
  mySprite.y = 0
  mySprite.vx = 0
  mySprite.vy = 0
  
  mySprite.width = mySprite.images[0]:getWidth()
  mySprite.height = mySprite.images[0]:getHeight()
  
  table.insert(pList, mySprite)
  
  return mySprite
end

function CreateHuman()
  
  local myHuman = {}
  myHuman = CreateSprite(lstSprites, "human", "human/survivor-move_handgun_", 19)
  myHuman.x = screenWidth / 2
  myHuman.y = (screenHeight / 6) * 5
  myHuman.angle = 0
  myHuman.life = 100
  myHuman.Hurt = function()
    myHuman.life = theHuman.life - 0.05
    if myHuman.life <= 0 then
      myHuman.life = 0
      myHuman.visible = false
      current_screen = "gameover"
    end
  end
  
  return myHuman
end

function CreateZombie()
  
  local myZombie = CreateSprite(lstSprites, "zombie", "monster/skeleton-move_", 16)
  myZombie.x = math.random(10, screenWidth - 10)
  myZombie.y = math.random(10, screenHeight/2 - 10)
  myZombie.speed = math.random(10,30)/50
  
  myZombie.range = math.random(10, 150)
  myZombie.target = nil
  
  myZombie.state = ZSTATES.NONE
end

function UpdateZombie(pZombie, pEntities)

  if pZombie.state == ZSTATES.NONE then
    pZombie.state = ZSTATES.CHANGEDIR
  elseif pZombie.state == ZSTATES.WALK then
    
    -- Collisions with borders
    local bCollide = false
    if pZombie.x < 0 then
      pZombie.x = 0
      bCollide = true
    end
    if pZombie.x > screenWidth then
      pZombie.x = screenWidth
      bCollide = true
    end
    if pZombie.y < 0 then
      pZombie.y = 0
      bCollide = true
    end
    if pZombie.y > screenHeight then
      pZombie.y = screenHeight
      bCollide = true
    end
    if bCollide then
      pZombie.state = ZSTATES.CHANGEDIR
    end
  
    -- Look for humans!
    local i
    for i,sprite in ipairs(pEntities) do
      if sprite.type == "human" and sprite.visible == true then
        local distance = math.dist(sprite.x, sprite.y, pZombie.x, pZombie.y)
        if distance < pZombie.range then
          pZombie.state = ZSTATES.ATTACK
          pZombie.target = sprite
        end
      end
    end
    
  elseif pZombie.state == ZSTATES.ATTACK then
    
    if pZombie.target == nil then
      pZombie.state = ZSTATES.CHANGEDIR
    elseif math.dist(pZombie.target.x, pZombie.target.y, pZombie.x, pZombie.y) > pZombie.range    
        and pZombie.target.type == "human" then
      pZombie.state = ZSTATES.CHANGEDIR
    elseif math.dist(pZombie.target.x, pZombie.target.y, pZombie.x, pZombie.y) < 5 
        and pZombie.target.type == "human" then
      pZombie.state = ZSTATES.BITE
      pZombie.vx = 0
      pZombie.vy = 0
    else
      -- Attack!!!
      local destX, destY
      destX = math.random(pZombie.target.x, pZombie.target.x)
      destY = math.random(pZombie.target.y, pZombie.target.y)
      local angle = math.angle(pZombie.x, pZombie.y, destX, destY)
      pZombie.vx = pZombie.speed * 2 * 60 * math.cos(angle)
      pZombie.vy = pZombie.speed * 2 * 60 * math.sin(angle)
      pZombie.angle = angle
    end
    
  elseif pZombie.state == ZSTATES.BITE then
    if math.dist(pZombie.target.x, pZombie.target.y, pZombie.x, pZombie.y) > 5  then
      pZombie.state = ZSTATES.ATTACK
      biteSound:stop()
    else
      if pZombie.target.Hurt ~= nil then
        biteSound:play()
        pZombie.target.Hurt()
      end
      if pZombie.target.visible == false then
        pZombie.state = ZSTATES.CHANGEDIR
        biteSound:stop()
      end
    end
  
  elseif pZombie.state == ZSTATES.CHANGEDIR then
    local angle = math.angle(pZombie.x, pZombie.y, math.random(0, screenWidth), math.random(0, screenHeight))
    pZombie.vx = pZombie.speed * 60 * math.cos(angle)
    pZombie.vy = pZombie.speed * 60 * math.sin(angle)
    pZombie.angle = angle
    pZombie.state = ZSTATES.WALK
  end

  -- Collisions with borders
    if pZombie.x < 0 then
      pZombie.x = 0
    end
    if pZombie.x > screenWidth then
      pZombie.x = screenWidth
    end
    if pZombie.y < 0 then
      pZombie.y = 0
    end
    if pZombie.y > screenHeight then
      pZombie.y = screenHeight
    end

end

function love.load()
  
  bg = love.graphics.newImage("images/background.jpg")
  menu_bg = love.graphics.newImage("images/bg-menu.jpg")
  gameover_bg = love.graphics.newImage("images/bg-gameover.jpg")
  
  love.window.setMode(1024, 768, {resizable=true, vsync=false, minwidth=800, minheight=600})
  
  love.window.setTitle("Escape from the Zombies")
  
  gameMusic = love.audio.newSource("sounds/music_game.mp3", "stream")
  zombieSound = love.audio.newSource("sounds/zombie_sound.wav", "stream")
  biteSound = love.audio.newSource("sounds/bite_sound.wav", "static")
  
  screenWidth = love.graphics.getWidth()
  screenHeight = love.graphics.getHeight()
  
  -- Resizes the light world to fit a custom window size
  newLightWorld:Resize(screenWidth, screenHeight)
  
  theHuman = CreateHuman()
  
  -- Create a light on the light world with a custom radius
  newLight = Light:new(newLightWorld, 200)
  -- Set the light's color to white
  newLight:SetColor(255, 255, 255, 255)
  -- Set the light's position
  newLight:SetPosition(theHuman.x+100, theHuman.y+10)
  
  local nZombie
  for nZombie=1,100 do
    CreateZombie()
  end
  
end

function love.update(dt)
  
  if current_screen == "menu" then
    
    gameMusic:play()
    end
    
    if current_screen == "game" then
    
    gameMusic:setVolume(0.1)
    
    -- Recalculate the light world
    newLightWorld:Update()
    
    zombieSound:play()
    zombieSound:setVolume(0.3)
    
    local i
    for i,sprite in ipairs(lstSprites) do
      if sprite.type == "human" then
        sprite.currentFrame = sprite.currentFrame + 0.2 * 60 * dt
      elseif
        sprite.type == "zombie" then
        sprite.currentFrame = sprite.currentFrame + 0.2 * 50 * dt
      end
      if sprite.currentFrame >= #sprite.images then
        sprite.currentFrame = 0
      end
      -- Velocity
      sprite.x = sprite.x + sprite.vx * dt
      sprite.y = sprite.y + sprite.vy * dt
      
      if sprite.type == "zombie" then
        UpdateZombie(sprite, lstSprites)
      end
    end

    if love.keyboard.isDown("left") then
      theHuman.angle = -180
      if theHuman.x >= 30 then
        theHuman.x = theHuman.x - 2 * 60 * dt
      end
      newLight:SetPosition(theHuman.x-100, theHuman.y-10)
    end
    if love.keyboard.isDown("up") then
      theHuman.angle = -90
      if theHuman.y >= 30 then
        theHuman.y = theHuman.y - 2 * 60 * dt
      end
      newLight:SetPosition(theHuman.x+10, theHuman.y-100)
    end
    if love.keyboard.isDown("right") then
      theHuman.angle = 0
      if theHuman.x <= screenWidth - 30 then
        theHuman.x = theHuman.x + 2 * 60 * dt
      end
      newLight:SetPosition(theHuman.x+100, theHuman.y+10)
    end
    if love.keyboard.isDown("down") then
      theHuman.angle = 90
      if theHuman.y <= screenHeight - 30 then
        theHuman.y = theHuman.y + 2 * 60 * dt
      end
      newLight:SetPosition(theHuman.x-10, theHuman.y+100)
    end
    
    if love.keyboard.isDown("left") and love.keyboard.isDown("up") then
      theHuman.angle = - 135
      newLight:SetPosition(theHuman.x-50, theHuman.y-80)
    end
    if love.keyboard.isDown("up") and love.keyboard.isDown("right") then
      theHuman.angle = -45
      newLight:SetPosition(theHuman.x+70, theHuman.y-70)
    end
    if love.keyboard.isDown("right") and love.keyboard.isDown("down") then
      theHuman.angle = 45
      newLight:SetPosition(theHuman.x+70, theHuman.y+70)
    end
    if love.keyboard.isDown("down") and love.keyboard.isDown("left") then
      theHuman.angle = 135
      newLight:SetPosition(theHuman.x-80, theHuman.y+60)
    end
  end
  
end

function drawGame()
  
    love.graphics.draw(bg, 0, 0)
    
    local i
    for i,sprite in ipairs(lstSprites) do
      if sprite.visible == true then
        local frame = sprite.images[math.floor(sprite.currentFrame)]       -- We use math.floor because in the Update(dt) function, we add float numbers to the currentframe
        if sprite.type == "human" then
        love.graphics.draw(frame, sprite.x, sprite.y, math.rad(sprite.angle), 1, 1, sprite.width / 2, sprite.height / 2)
        end
        if sprite.type == "zombie" then
          love.graphics.draw(frame, sprite.x, sprite.y, sprite.angle, 1, 1, sprite.width / 2, sprite.height / 2)
          if sprite.state == ZSTATES.ATTACK then
            love.graphics.draw(imgAlert,
              sprite.x - imgAlert:getWidth()/2,
              sprite.y - 40)
          end
        end
      end
    end
    
    -- Draw the light world with white color
    newLightWorld:Draw()
    
    -- Draw human life
    love.graphics.print("LIFE:"..tostring(math.floor(theHuman.life)), 10, 10)
  end
  
  function drawMenu()
    love.graphics.draw(menu_bg, 0, 0)
  end
  
  function drawGameOver()
    love.graphics.draw(gameover_bg, 0, 0)
  end

function love.draw()
  
  if current_screen == "game" then
    drawGame()
  elseif current_screen == "menu" then
    drawMenu()
  elseif current_screen == "gameover" then
    drawGameOver()
  end
  
end

function love.keypressed(key)
  
  if current_screen == "menu" then
    if key == "space" then
      current_screen = "game"
    end
  elseif current_screen == "gameover" then
    if key == "space" then
      love.event.quit( "restart" )
    end
  end
  
end

