
local lstSprites = {}

local theHuman = {}

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

function love.load()
  
  love.window.setMode(1024, 768, {resizable=true, vsync=false, minwidth=800, minheight=600})
  
  love.window.setTitle("Escape from the Zombies")
  
  screenWidth = love.graphics.getWidth()
  screenHeight = love.graphics.getHeight()
  
  theHuman = CreateHuman()
  
end

function love.update(dt)

  local i
  for i,sprite in ipairs(lstSprites) do
    sprite.currentFrame = sprite.currentFrame + 0.2 * 60 * dt
    if sprite.currentFrame >= #sprite.images then
      sprite.currentFrame = 0
    end
    -- Velocity
    sprite.x = sprite.x + sprite.vx * dt
    sprite.y = sprite.y + sprite.vy * dt
    
  end

  if love.keyboard.isDown("left") then
    theHuman.angle = - 180
    theHuman.x = theHuman.x - 1 * 60 * dt
  end
  if love.keyboard.isDown("up") then
    theHuman.angle = -90
    theHuman.y = theHuman.y - 1 * 60 * dt
  end
  if love.keyboard.isDown("right") then
    theHuman.angle = 0
    theHuman.x = theHuman.x + 1 * 60 * dt
  end
  if love.keyboard.isDown("down") then
    theHuman.angle = 90
    theHuman.y = theHuman.y + 1 * 60 * dt
  end
  
  if love.keyboard.isDown("left") and love.keyboard.isDown("up") then
    theHuman.angle = - 135
    theHuman.x = theHuman.x - 1 * dt
    theHuman.y = theHuman.y - 1 * dt
  end
  if love.keyboard.isDown("up") and love.keyboard.isDown("right") then
    theHuman.angle = -45
    theHuman.y = theHuman.y - 1 * dt
    theHuman.x = theHuman.x + 1 * dt
  end
  if love.keyboard.isDown("right") and love.keyboard.isDown("down") then
    theHuman.angle = 45
    theHuman.x = theHuman.x + 1 * dt
    theHuman.y = theHuman.y + 1 * dt
  end
  if love.keyboard.isDown("down") and love.keyboard.isDown("left") then
    theHuman.angle = 135
    theHuman.x = theHuman.x - 1 * dt
    theHuman.y = theHuman.y + 1 * dt
  end

end

function love.draw()
  
  love.graphics.print("LIFE:"..tostring(math.floor(theHuman.life)), 1, 1)
  
  local i
  for i,sprite in ipairs(lstSprites) do
    if sprite.visible == true then
      local frame = sprite.images[math.floor(sprite.currentFrame)]       -- We use math.floor because in the Update(dt) function, we add float numbers to the currentframe
      love.graphics.draw(frame, sprite.x, sprite.y, math.rad(sprite.angle), 1, 1, sprite.width / 2, sprite.height / 2)
    end
  end
    
end

