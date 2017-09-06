vector = require("vector")

local score = 0
local highscore = 0
local reflectCount = 0
local speedupOnCount = 2
local speedupValue = 1.25
local paddleSpeedUpValue = 1.15
local gamestate = 'play'
local highscoreGet = false
--
--colors
local colors = {}
colors.red = {
  value = {200, 40, 40, 255}, 
  name = 'red'}
colors.green = {
  value = {40, 200, 40, 255}, 
  name = 'green'}
colors.blue = {
  value = {40, 40, 220, 255}, 
  name = 'blue'}
local colorsSide = {}
colorsSide.gray = {
  value = {180, 180, 180, 255},
  name = 'gray'}
colorsSide.white = {
  value = {255, 255, 255, 255},
  name = 'white'}
--
--paddle
local paddle = {}
paddle.init = function()
  paddle.position = vector(50, 520)
  paddle.size = vector(100, 20)
  paddle.speed = vector(0, 0)
  paddle.color = colors.red
  paddle.defSpeed = 200
end
paddle.update = function(dt)
  if not (love.keyboard.isScancodeDown('left') or love.keyboard.isScancodeDown('right')) then
    paddle.speed = vector(0, 0)
  end
  paddle.position = paddle.position + dt*paddle.speed  
end
paddle.draw = function()
  love.graphics.setColor(paddle.color.value)
  love.graphics.rectangle('fill', paddle.position.x, paddle.position.y, paddle.size.x, paddle.size.y)
end
paddle.rebound = function(shift)
  paddle.position.x = paddle.position.x - shift.x
end
--
--ball
local ball = {}
ball.init = function()
  ball.position = vector(100, 100)
  ball.size = vector(50, 50)
  ball.speed = vector.fromPolar(math.pi/2 + math.pi * love.math.random()/4, 300)
  ball.color = colors.red
end
ball.update = function(dt)
  ball.position = ball.position + dt*ball.speed
  animation.addParticle(ball.position, ball.size, ball.color, vector(0,0), vector(-100, -100), {0,0,0, 255*2}, 0.5)
end
ball.draw = function()
  love.graphics.setColor(ball.color.value)
  love.graphics.rectangle('fill', ball.position.x, ball.position.y, ball.size.x, ball.size.y)
end
ball.rebound = function(shift)
  local minShift = math.min(math.abs(shift.x),
                   math.abs(shift.y))
  if math.abs(shift.x) == minShift then
    ball.position.x = ball.position.x - shift.x
    ball.speed.x = -ball.speed.x
  else
    ball.position.y = ball.position.y - shift.y
    ball.speed.y = -ball.speed.y
  end
end
ball.setRandomColor = function()
  local keys, i = {}, 1
  for k,_ in pairs(colors) do
   keys[i] = k
   i = i + 1
  end
   m = math.random(1,#keys)
   ball.color = colors[keys[m]]
end
ball.randomizeAngleFromWall = function()
  local phi = (love.math.random() - 0.5) * math.pi/4
  local alteredVector = ball.speed:rotated(phi)
  ball.speed = alteredVector
end
--
--walls
local walls = {}
walls.currentWalls = {}
walls.init = function()
  local wallL = walls.newWall(
    0,
    0,
    20,
    600,
    'wall'
  )
  local wallR = walls.newWall(
    420,
    0,
    20,
    600,
    'wall'
  )
  local wallT = walls.newWall(
    0,
    0,
    420,
    20,
    'score'
  )
  local wallB = walls.newWall(
    0,
    580,
    420,
    20,
    'lose'
  )
  walls.currentWalls["left"] = wallL
  walls.currentWalls["right"] = wallR
  walls.currentWalls["top"] = wallT
  walls.currentWalls["bottom"] = wallB
end
walls.draw = function()
  love.graphics.setColor(colorsSide.gray.value)
  for _,wall in pairs(walls.currentWalls) do
    love.graphics.rectangle('fill', wall.position.x, wall.position.y, wall.size.x, wall.size.y)
  end
end
walls.newWall = function(positionX, positionY, width, height, state)
   return( { position = vector(positionX, positionY),
             size = vector(width, height),
             state = state} )
end
walls.resolveState = function(state)
  if state == 'wall' then
    --nothing
  elseif state == 'score' then
    score = score + 1
    ball.setRandomColor()
    animation.addParticle(ball.position, ball.size, ball.color, vector(0,0), vector(100, 100), {0,0,0, 255}, 1)
    reflectCount = reflectCount + 1
    if reflectCount >= speedupOnCount then
      reflectCount = 0
      ball.speed = ball.speed * speedupValue
      paddle.defSpeed = paddle.defSpeed * paddleSpeedUpValue
      ball.randomizeAngleFromWall()
      animation.addParticle(ball.position, ball.size, colorsSide.white, vector(0,0), vector(150, 150), {0,0,0, 255*2}, 0.5)
    end
  elseif state == 'lose' then
    gamestate = 'gameover'
    if highscore < score then
      saveHighscore()
      highscoreGet = true
    end
  end
end
--
--collisions
local collisions = {}
collisions.resolveCollisions = function()
  collisions.ballWallsCollision(ball, walls)
  collisions.ballPaddleCollision(ball, paddle)
  collisions.paddleWallCollision(paddle, walls)
end
collisions.ballWallsCollision = function(ball, walls)
  for i, wall in pairs(walls.currentWalls) do
    overlap, shift = collisions.checkRectanglesOverlap(ball, wall)    
    if overlap then
      ball.rebound(shift)
      walls.resolveState(wall.state)
    end   
  end
end
collisions.ballPaddleCollision = function(ball, paddle)
   overlap, shift = collisions.checkRectanglesOverlap(ball, paddle)    
  if overlap then
    ball.rebound(shift)
    if not (ball.color.name == paddle.color.name) then
      gamestate = 'gameover'
    end
  end
end
collisions.paddleWallCollision = function(paddle, walls)
  for _, wall in pairs(walls.currentWalls) do
    overlap, shift = collisions.checkRectanglesOverlap(paddle, wall)    
    if overlap then
      paddle.rebound(shift)
    end
  end
end
collisions.checkRectanglesOverlap = function(a, b)
   local overlap = false
   local shift = vector(0,0)
   if not( a.position.x + a.size.x < b.position.x or 
           b.position.x + b.size.x < a.position.x or
           a.position.y + a.size.y < b.position.y or 
           b.position.y + b.size.y < a.position.y ) then
    overlap = true
    if ( a.position.x + a.size.x / 2 ) < ( b.position.x + b.size.x / 2 ) then
      shift.x = ( a.position.x + a.size.x ) - b.position.x                    
    else 
      shift.x = a.position.x - ( b.position.x + b.size.x )                    
    end
    if ( a.position.y + a.size.y / 2 ) < ( b.position.y + b.size.y / 2 ) then
      shift.y = ( a.position.y + a.size.y ) - b.position.y                    
    else
      shift.y = a.position.y - ( b.position.y + b.size.y ) 
    end
   end
   return overlap, shift
   
end
--
--animations
animation = {}
animation.particles = {}
animation.update = function(dt)
  for i,particle in ipairs(animation.particles) do
    particle.TTL = particle.TTL - dt
    particle.size = particle.size + particle.dSize/2 * dt
    particle.position = particle.position - particle.dSize/4 * dt
    doDColor(particle.color, particle.dColor, dt)
    if particle.TTL <= 0 then 
      table.remove(animation.particles, i) 
    end
  end
end
animation.draw = function()
  for _,particle in pairs(animation.particles) do
      love.graphics.setColor(particle.color.value)
      love.graphics.rectangle('fill', particle.position.x, particle.position.y, particle.size.x, particle.size.y)
  end
end
animation.addParticle = function(position, size, color, dPosition, dSize, dColor, TTL)
  local particle = {
    position = position,
    size = size,
    color = deepCopy(color),
    dPosition = dPosition,
    dSize = dSize,
    dColor = dColor,
    TTL = TTL}
  table.insert(animation.particles, particle)
end
animation.clear = function()
  while #animation.particles > 0 do table.remove(animation.particles) end
end
--
--generalpurpose
function reset()
  paddle.init()
  ball.init()
  walls.init()
  animation.clear()
  score = 0
  reflectCount = 0
  loadHighscore()
  highscoreGet = false
  gamestate = 'play'
end
function deepCopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end
function loadHighscore()
  local savestring = love.filesystem.read("score.dat")
  pcall(function() highscore = 0 + savestring end)
end
function saveHighscore()
  local savestring = score
  love.filesystem.write("score.dat", savestring)
end
function writeSidebar()
  local colorHue = {0, 0, 255/8, 55}
  local colorT = deepCopy(colors.red)
  doDColor(colorT, colorHue)
  love.graphics.setColor(colorT.value)
  love.graphics.print('T', 450+5, 20, 0, 3, 3)
  
  colorT = deepCopy(colors.green)
  doDColor(colorT, colorHue)
  love.graphics.setColor(colorT.value)
  love.graphics.print('R', 505+5, 20, 0, 3, 3)
  
  colorT = deepCopy(colors.blue)
  doDColor(colorT, colorHue)
  love.graphics.setColor(colorT.value)
  love.graphics.print('I', 560+5, 20, 0, 3, 3)
  
  colorT = deepCopy(colorsSide.white)
  doDColor(colorT, colorHue)
  love.graphics.setColor(colorT.value)
  love.graphics.print('PADDLE', 590+4, 40, 0, 2, 2)
  
  love.graphics.setColor(colors.red.value)
  love.graphics.print('T', 450, 20, 0, 3, 3)
  love.graphics.setColor(colors.green.value)
  love.graphics.print('R', 505, 20, 0, 3, 3)
  love.graphics.setColor(colors.blue.value)
  love.graphics.print('I', 560, 20, 0, 3, 3)
  love.graphics.setColor(colorsSide.white.value)
  love.graphics.print('PADDLE', 590, 40, 0, 2, 2)

  love.graphics.setColor(colorsSide.gray.value)
  love.graphics.print('Score: '..score..'\nHigh Score: \n                '..highscore, 460, 160, 0, 2, 2)
  
  love.graphics.printf('Control paddle with left and right arrows\n\n'..
                      'Ball should be reflected with same color paddle\n\n'..
                      'Change color with Z, X and C buttons',
                      460, 350, 800-460, 'center', 0, 0.8, 0.8)
end
function doDColor(color, dColor, dt)
  dt = dt or 1
  for i, oneValue in ipairs(color.value) do
    color.value[i] = oneValue - dColor[i] * dt
  end
end
--
--love
function love.load(arg)
  if arg[#arg] == "-debug" then require("mobdebug").start() end
  
  love.keyboard.setKeyRepeat = False
  love.graphics.setDefaultFilter('nearest')
  local font = love.graphics.newFont("assets/FFFFORWA.TTF",20)
  love.graphics.setFont(font)
  
  reset()
end
function love.update(dt)
  if gamestate == 'play' then
    paddle.update(dt)
    ball.update(dt)
    collisions.resolveCollisions()
    animation.update(dt)
  end
end
function love.keypressed(key, scancode, isrepeat)
  if gamestate == 'play' then
    if scancode == 'left' then
      paddle.speed = vector(-paddle.defSpeed, 0)
    elseif scancode == 'right' then
      paddle.speed = vector(paddle.defSpeed, 0)
    end
    if scancode == 'z' then
      paddle.color = colors.red
    elseif scancode == 'x' then
      paddle.color = colors.green
    elseif scancode == 'c' then
      paddle.color = colors.blue
    end
    if not isrepeat and
           scancode == 'z' or
           scancode == 'x' or
           scancode == 'c' then
      animation.addParticle(paddle.position, paddle.size, paddle.color, vector(0,0), vector(80, 80), {0,0,0, 255/0.3}, 0.3)
    end 
  end
  
  if scancode == 'return' and gamestate == 'gameover' then
    reset()
  end
end
function love.draw()
  paddle.draw()
  ball.draw()
  walls.draw()
  animation.draw()
  writeSidebar()
  
  if gamestate == 'gameover' then
    love.graphics.print('Game Over\nPress Enter to continue', 80,200)
    if highscoreGet then
      love.graphics.print('NEW HIGH SCORE!', 80,300)
    end
  end
end
