function love.conf(t)
  t.window.title = "TriPaddle by EasternMouse"
  t.identity = "Mouse_TriPaddle"
  t.window.width = 800 
  t.window.height = 600
  
  t.modules.audio = true
  t.modules.event = true
  t.modules.graphics = true
  t.modules.image = false
  t.modules.joystick = true
  t.modules.keyboard = true
  t.modules.math = true
  t.modules.mouse = false
  t.modules.physics = false
  t.modules.sound = true
  t.modules.system = false
  t.modules.timer = true
  t.modules.touch = false
  t.modules.video = false
  t.modules.window = true
  t.modules.thread = false
end
