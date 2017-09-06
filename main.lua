vector = require("vector")

local score = 0
local speed = 1
local gamestate = 'play'
local animations = {}
--
--colors
local colors = {}
colors.red = {
  value = {200, 40, 40}, 
  name = 'red'}
colors.green = {
  value = {40, 200, 40}, 
  name = 'green'}
colors.blue = {
  value = {40, 40, 200}, 
  name = 'blue'}
--
--paddle
local paddle = {}
paddle.init = function()
  paddle.position = vector(50, 520)
  paddle.size = vector(100, 20)
  paddle.speed = vector(0, 0)
  paddle.color = colors.red
end
paddle.update = function(dt)
  if love.keyboard.isDown('left') then
    paddle.speed = vector(-200, 0)
  elseif love.keyboard.isDown('right') then
    paddle.speed = vector(200, 0)
  else
    paddle.speed = vector(0, 0)
  end
  if love.keyboard.isDown('z') then
    paddle.color = colors.red
  elseif love.keyboard.isDown('x') then
    paddle.color = colors.green
  elseif love.keyboard.isDown('c') then
    paddle.color = colors.blue
  end
  --
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
  love.graphics.setColor(180,180,180)
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
    
  elseif state == 'score' then
    score = score + 1
    ball.setRandomColor()
  elseif state == 'lose' then
    gamestate = 'gameover'
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
function waitForContinueFromGameOver()
  if love.keyboard.isDown("return") then
    paddle.init()
    ball.init()
    walls.init()
    score = 0
    gamestate = 'play'
  end
end
--
--love
function love.load(arg)
  if arg[#arg] == "-debug" then require("mobdebug").start() end
  
  love.graphics.setDefaultFilter('nearest')
  local font = love.graphics.newFont("assets/FFFFORWA.TTF",20)
  love.graphics.setFont(font)
  paddle.init()
  ball.init()
  walls.init()
  gamestate = 'play'
end
function love.update(dt)
  if gamestate == 'play' then
    paddle.update(dt)
    ball.update(dt)
    collisions.resolveCollisions()
  elseif gamestate == 'gameover' then
    waitForContinueFromGameOver()
  end
end
function love.keypressed(key, scancode, isrepeat)
  
end
function love.draw()
  paddle.draw()
  ball.draw()
  walls.draw()
  --
  love.graphics.print('Score: '..score, 460, 20,0,2,2)
  if gamestate == 'gameover' then
    love.graphics.print('Game Over \n Press Enter to continue', 80,200)
  end
end
