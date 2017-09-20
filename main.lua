vector = require("vector")

version = 'v0.8'
local score = '?'
local highscore = 0
local reflectCount = 0
local speedupOnCount = 3
local speedupValue = 1.2
local paddleSpeedUpValue = 1.15
local gamestate = 'mainmenu' --todo gameover OK | play OK | options | pausemenu
local highscoreGet = false
local gameOptions = {}
gameOptions.volumeSE = 5
--
--sounds
sounds = {}
sounds.loadSounds = function()
  sounds.hit1 = love.audio.newSource('assets/hit1.wav', 'static')
  sounds.hit2 = love.audio.newSource('assets/hit2.wav', 'static')
  sounds.lose = love.audio.newSource('assets/lose.wav', 'static')
end
sounds.play = function(sound)
  if sound:isPlaying() then
    sound:rewind()
  else
    sound:play()
  end
end
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
colorsSide.black = {
  value = {0, 0, 0, 225},
  name = 'black'}
--
--paddle
local paddle = {}
paddle.init = function()
  paddle.position = vector(170, 520)
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
  ball.position = vector(200, 50)
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
  ball.minAngle()
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
  local phi = love.math.randomNormal(1,0) * math.pi/4
  local alteredVector = ball.speed:rotated(phi)
  ball.speed = alteredVector
  ball.speed.y = math.abs(ball.speed.y)
end
ball.reboundFromPaddle = function(shift, paddle)
   local actualShift = ball.determineActualShift(shift)
   ball.position = ball.position - actualShift
   if actualShift.x ~= 0 then
      ball.speed.x = -ball.speed.x
   end
   if actualShift.y ~= 0 then
      local sphereRadius = 200
      local ballCenter = ball.position + ball.size/2
      local platformCenter = paddle.position + paddle.size/2
      local separation = (ballCenter - platformCenter)
      local normalDirection = vector(separation.x/sphereRadius, -1)
      local vNorm = ball.speed:projectOn(normalDirection )
      local vTan = ball.speed - vNorm
      local reverseVNorm = vNorm * (-1)
      ball.speed = reverseVNorm + vTan
      ball.speed.y = -math.abs(ball.speed.y)
   end
end

ball.determineActualShift = function(shiftBall)
   local actualShift = vector(0, 0)
   local minShift = math.min(math.abs(shiftBall.x ),
                             math.abs(shiftBall.y))  
   if math.abs(shiftBall.x) == minShift then
      actualShift.x = shiftBall.x
   else
      actualShift.y = shiftBall.y
   end
   return actualShift
end
ball.minAngle = function()
   local minHorizontalAngle = math.rad( 20 )
   local vX, vY = ball.speed:unpack()
   local newVX, newVY = vX, vY
   reboundAngle = math.abs(math.atan(vY/vX))
   if reboundAngle < minHorizontalAngle then
      newVX = sign(vX) * ball.speed:len() *
         math.cos(minHorizontalAngle)
      newVY = sign(vY) * ball.speed:len() *
         math.sin(minHorizontalAngle)
   end
   ball.speed = vector(newVX, newVY)
end
--
--walls
local walls = {}
walls.currentWalls = {}
walls.init = function()
--drawable 
  walls.newWall(
    0,
    0,
    20,
    600,
    'draw')
  walls.newWall(
    420,
    0,
    20,
    600,
    'draw')
  walls.newWall(
    0,
    0,
    420,
    20,
    'draw')
  walls.newWall(
    0,
    580,
    420,
    20,
    'draw')
  
--colision  
  walls.newWall(
    0-400,
    0-400,
    20+400,
    600+400,
    'wall')
  walls.newWall(
    420,
    0-400,
    20+400,
    600+400,
    'wall')
  walls.newWall(
    0-400,
    0-400,
    420+800,
    20+400,
    'score')
  walls.newWall(
    0-400,
    580,
    420+800,
    20+400,
    'lose')
end
walls.draw = function()
  love.graphics.setColor(colorsSide.gray.value)
  for _,wall in pairs(walls.currentWalls) do
    if wall.state == 'draw' then
      love.graphics.rectangle('fill', wall.position.x, wall.position.y, wall.size.x, wall.size.y)
    end
  end
end
walls.newWall = function(positionX, positionY, width, height, state)
  table.insert(walls.currentWalls,
            {position = vector(positionX, positionY),
             size = vector(width, height),
             state = state})
end
walls.resolveState = function(state)
  if state == 'wall' then
    sounds.play(sounds.hit2)
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
      animation.addParticle(ball.position, ball.size, colorsSide.white, vector(0,0), vector(300, 300), {0,0,0, 255*2}, 0.5)
    end
    sounds.play(sounds.hit2)
  elseif state == 'lose' then
    gamestate = 'gameover'
    sounds.play(sounds.lose)
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
    if wall.state ~= 'draw' then
      local overlap, shift = collisions.checkRectanglesOverlap(ball, wall)    
      if overlap then
        ball.rebound(shift)
        walls.resolveState(wall.state)
      end
    end
  end
end
collisions.ballPaddleCollision = function(ball, paddle)
  local overlap, shift = collisions.checkRectanglesOverlap(ball, paddle)    
  if overlap then
    ball.reboundFromPaddle(shift, paddle)
    --ball.rebound(shift)
    if not (ball.color.name == paddle.color.name) then
      gamestate = 'gameover'
      sounds.play(sounds.lose)
      if highscore < score then
        saveHighscore()
        highscoreGet = true
      end
    end
    sounds.play(sounds.hit1)
  end
end
collisions.paddleWallCollision = function(paddle, walls)
  for _, wall in pairs(walls.currentWalls) do
    local overlap, shift = collisions.checkRectanglesOverlap(paddle, wall)    
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
  animation.clear()
  score = 0
  reflectCount = 0
  loadHighscore()
  highscoreGet = false
  gamestate = 'play'
end
function initgame()
  walls.init()
  loadHighscore()
  menu.init()
  options.init()
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
  
  love.graphics.print(version, 660+4, 100, 0, 1.5, 1)
  
  love.graphics.setColor(colors.red.value)
  love.graphics.print('T', 450, 20, 0, 3, 3)
  love.graphics.setColor(colors.green.value)
  love.graphics.print('R', 505, 20, 0, 3, 3)
  love.graphics.setColor(colors.blue.value)
  love.graphics.print('I', 560, 20, 0, 3, 3)
  love.graphics.setColor(colorsSide.white.value)
  love.graphics.print('PADDLE', 590, 40, 0, 2, 2)
  
  love.graphics.print(version, 660, 100, 0, 1.5, 1)

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

function backToMenu()
  animation.clear()
  gamestate = 'mainmenu'
  score = '?'
end
sign = math.sign or function(x) return x < 0 and -1 or x > 0 and 1 or 0 end
--
--mainmenu
menu = {}
menu.buttons = {}
menu.currentButton = 1
menu.addButton = function(tableIn, name, position, size, sizeText, f, fLR)
  table.insert(tableIn, {
      name = name,
      position = position,
      size = size,
      f = f,
      color = colorsSide.gray,
      textColor = colorsSide.white,
      sizeText = sizeText,
      fLR = fLR}) --function Left Right
end
menu.buttonHighlight = function(tableIn, highlightedButton)
  for _, button in ipairs(tableIn) do
    button.color = colorsSide.gray
    button.textColor = colorsSide.white
  end
  highlightedButton.color = colorsSide.white
  highlightedButton.textColor = colorsSide.black
end
menu.controlButtons = function(key)
  if key == 'up' and menu.currentButton ~= 1 then
    menu.currentButton = menu.currentButton - 1
    menu.buttonHighlight(menu.buttons, menu.buttons[menu.currentButton])
  elseif key == 'down' and menu.currentButton ~= #menu.buttons then
    menu.currentButton = menu.currentButton + 1
    menu.buttonHighlight(menu.buttons, menu.buttons[menu.currentButton])
  elseif key == 'return' then
    if menu.buttons[menu.currentButton].f then menu.buttons[menu.currentButton].f() end
  end
end
menu.init = function()
  menu.addButton(
    menu.buttons,
    'Start',
    vector(60, 100),
    vector(225, 90),
    3,
    menu.playButton)
  menu.addButton(
    menu.buttons,
    'Options',
    vector(60, 100+100),
    vector(310, 110),
    3,
    menu.optionButton)
  menu.addButton(
    menu.buttons,
    'Exit',
    vector(60, 100+220),
    vector(160, 90),
    3,
    menu.exitButton)
  menu.buttonHighlight(menu.buttons, menu.buttons[1])
end
menu.draw = function()
  for _, button in ipairs(menu.buttons) do
    love.graphics.setColor(button.color.value)
    love.graphics.rectangle('fill', button.position.x, button.position.y, button.size.x, button.size.y)
    love.graphics.setColor(button.textColor.value)
    love.graphics.print(button.name, button.position.x+5, button.position.y+15, 0, button.sizeText, button.sizeText)
  end
end

menu.exitButton = function()
  os.exit()
end
menu.playButton = function()
  reset()
  gamestate = 'play'
end

menu.optionButton = function()
  gamestate = 'options'
end
--
--options
options = {}
options.buttons = {}
options.currentButton = 1
options.init = function()
  menu.addButton(
    options.buttons,
    'Reset Highscore',
    vector(60, 100),
    vector(225, 54),
    1,
    options.resetHighscore)
  menu.addButton(
    options.buttons,
    'Sound Effects',
    vector(60, 170),
    vector(225, 54),
    1,
    nil,
    options.volumeLR)
  menu.buttonHighlight(options.buttons, options.buttons[1])
end
options.draw = function()
  for _, button in ipairs(options.buttons) do
    love.graphics.setColor(button.color.value)
    love.graphics.rectangle('fill', button.position.x, button.position.y, button.size.x, button.size.y)
    love.graphics.setColor(button.textColor.value)
    love.graphics.print(button.name, button.position.x+5, button.position.y+15, 0, button.sizeText, button.sizeText)
    if button.fLR then
      for i=0, 9 do
        if i+1 <= gameOptions.volumeSE then
          love.graphics.setColor(colorsSide.white.value)
        else
          love.graphics.setColor(colorsSide.gray.value)
        end
        love.graphics.rectangle('fill', button.position.x + 30 * i, button.position.y + button.size.y + 15, 20, 40)
      end
    end
  end
end
options.controlButtons = function(key)
  if key == 'up' and options.currentButton ~= 1 then
    options.currentButton = options.currentButton - 1
    menu.buttonHighlight(options.buttons, options.buttons[options.currentButton])
  elseif key == 'down' and options.currentButton ~= #options.buttons then
    options.currentButton = options.currentButton + 1
    menu.buttonHighlight(options.buttons, options.buttons[options.currentButton])
  elseif key == 'return' then
    if options.buttons[options.currentButton].f then options.buttons[options.currentButton].f(key) end
  elseif key == 'left' or key == 'right' then
    if options.buttons[options.currentButton].fLR then options.buttons[options.currentButton].fLR(key) end
  end
end
options.volumeLR = function(key)
  if key == 'left' and gameOptions.volumeSE > 0 then
    gameOptions.volumeSE = gameOptions.volumeSE - 1
  elseif key == 'right' and gameOptions.volumeSE < 10 then
    gameOptions.volumeSE = gameOptions.volumeSE + 1
  end
  love.audio.setVolume(gameOptions.volumeSE/10)
  sounds.play(sounds.hit1)
end
options.resetHighscore = function()
  score = 0
  saveHighscore()
  score = '?'
  loadHighscore()
end
--
--love
function love.load(arg)
  if arg[#arg] == "-debug" then require("mobdebug").start() end
  
  love.graphics.setDefaultFilter('nearest')
  local font = love.graphics.newFont("assets/FFFFORWA.TTF",20)
  love.graphics.setFont(font)
  sounds.loadSounds()
  
  initgame()
end
function love.update(dt)
  if dt >= 0.3 then
    return
  end
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
      animation.addParticle(paddle.position, paddle.size, paddle.color, vector(0,0), vector(200, 200), {0,0,0, 255/0.15}, 0.15)
    end
  elseif gamestate == 'mainmenu' then
    menu.controlButtons(scancode)
  elseif gamestate == 'options' then
    if scancode == 'escape' then
      gamestate = 'mainmenu'
    else
      options.controlButtons(scancode)
    end
  end
  if gamestate == 'gameover' then
    if scancode == 'return' then
      reset()
    elseif scancode == 'escape' then
      backToMenu()
    end
  end
end
function love.draw()
  if gamestate == 'play' or gamestate == 'gameover' then
    paddle.draw()
    ball.draw()
  elseif gamestate == 'mainmenu' then
    menu.draw()
  elseif gamestate == 'options' then
    options.draw()
  end
  if gamestate == 'gameover' then
    local colorHue = {0, 0, 255/8, 55}
    local colorT = deepCopy(colorsSide.white)
    doDColor(colorT, colorHue)
    love.graphics.setColor(colorT.value)
    love.graphics.print('Game Over', 80+5, 80, 0, 2, 2)
    love.graphics.setColor(colorsSide.white.value)
    love.graphics.print('Game Over', 80, 80, 0, 2, 2)
    love.graphics.print('Press Enter to retry\n\nPress Esc to leave\n to main menu', 80,200)
    if highscoreGet then
      love.graphics.print('NEW HIGH SCORE!', 80,300)
    end
  end
  walls.draw()
  writeSidebar()
  animation.draw()
end
