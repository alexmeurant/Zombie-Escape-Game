
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
    myHuman.life = theHuman.life - 0.1
    if myHuman.life <= 0 then
      myHuman.life = 0
      myHuman.visible = false
    end
  end
  
  return myHuman
end

function CreateZombie()
  
  local myZombie = CreateSprite(lstSprites, "zombie", "monster/skeleton-move_", 16)
  myZombie.x = math.random(10, screenWidth - 10)
  myZombie.y = math.random(10, screenHeight - 10)
  myZombie.angle = 0
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
        local distance = ((sprite.x - pZombie.x)^2+(sprite.y - pZombie.y)^2)^0.5
        if distance < pZombie.range then
          pZombie.state = ZSTATES.ATTACK
          pZombie.target = sprite
        end
      end
    end
    
  elseif pZombie.state == ZSTATES.ATTACK then
    
    if pZombie.target == nil then
      pZombie.state = ZSTATES.CHANGEDIR
    elseif ((pZombie.target.x - pZombie.x)^2+(pZombie.target.y - pZombie.y)^2)^0.5 > pZombie.range    
        and pZombie.target.type == "human" then
      pZombie.state = ZSTATES.CHANGEDIR
      print("Lost contact")
    elseif ((pZombie.target.x - pZombie.x)^2+(pZombie.target.y - pZombie.y)^2)^0.5 < 5 
        and pZombie.target.type == "human" then
      pZombie.state = ZSTATES.BITE
      pZombie.vx = 0
      pZombie.vy = 0
    else
      -- Attack!!!
      local destX, destY
      destX = math.random(pZombie.target.x-20, pZombie.target.x+20)
      destY = math.random(pZombie.target.y-20, pZombie.target.y+20)
      local angle = math.atan2(destY -pZombie.y, destX - pZombie.x)
      pZombie.vx = pZombie.speed * 2 * 60 * math.cos(angle)
      pZombie.vy = pZombie.speed * 2 * 60 * math.sin(angle)
    end
    
  elseif pZombie.state == ZSTATES.BITE then
    if ((pZombie.target.x - pZombie.x)^2+(pZombie.target.y - pZombie.y)^2)^0.5 > 5  then
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
    local angleDirection = math.atan2(math.random(0, screenHeight) - pZombie.y, math.random(0, screenWidth) - pZombie.x)
    pZombie.vx = pZombie.speed * 60 * math.cos(angleDirection)
    pZombie.vy = pZombie.speed * 60 * math.sin(angleDirection)
  
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
  
  love.window.setMode(1024, 768, {resizable=true, vsync=false, minwidth=800, minheight=600})
  
  love.window.setTitle("Escape from the Zombies")
  
  zombieSound = love.audio.newSource("sounds/music_game.wav", "stream")
  biteSound = love.audio.newSource("sounds/bite_sound.wav", "static")
  
  screenWidth = love.graphics.getWidth()
  screenHeight = love.graphics.getHeight()
  
  theHuman = CreateHuman()
  
  local nZombie
  for nZombie=1,50 do
    CreateZombie()
  end
  
end

function love.update(dt)
  
  zombieSound:play()

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
    theHuman.x = theHuman.x - 2 * 60 * dt
  end
  if love.keyboard.isDown("up") then
    theHuman.angle = -90
    theHuman.y = theHuman.y - 2 * 60 * dt
  end
  if love.keyboard.isDown("right") then
    theHuman.angle = 0
    theHuman.x = theHuman.x + 2 * 60 * dt
  end
  if love.keyboard.isDown("down") then
    theHuman.angle = 90
    theHuman.y = theHuman.y + 2 * 60 * dt
  end
  
  if love.keyboard.isDown("left") and love.keyboard.isDown("up") then
    theHuman.angle = - 135
  end
  if love.keyboard.isDown("up") and love.keyboard.isDown("right") then
    theHuman.angle = -45
  end
  if love.keyboard.isDown("right") and love.keyboard.isDown("down") then
    theHuman.angle = 45
  end
  if love.keyboard.isDown("down") and love.keyboard.isDown("left") then
    theHuman.angle = 135
  end

end

function love.draw()
  
  love.graphics.draw(bg, 0, 0)
  
  love.graphics.print("LIFE:"..tostring(math.floor(theHuman.life)), 1, 1)
  
  local i
  for i,sprite in ipairs(lstSprites) do
    if sprite.visible == true then
      local frame = sprite.images[math.floor(sprite.currentFrame)]       -- We use math.floor because in the Update(dt) function, we add float numbers to the currentframe
      love.graphics.draw(frame, sprite.x, sprite.y, math.rad(sprite.angle), 1, 1, sprite.width / 2, sprite.height / 2)
      
      if sprite.type == "zombie" then
        love.graphics.draw(frame, sprite.x, sprite.y, sprite.angle, 1, 1, sprite.width / 2, sprite.height / 2)
        if sprite.state == ZSTATES.ATTACK then
          love.graphics.draw(imgAlert,
            sprite.x - imgAlert:getWidth()/2,
            sprite.y - sprite.height - 2)
        end
      end
    end
  end
    
end

