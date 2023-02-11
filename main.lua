local C, V, M = unpack(require "vector")
local S = require "symbol"

local sw, sh = love.graphics.getDimensions()

local xs = {}
xs[1] = C(1)
xs[2] = C(0)
xs[3] = C(0)
xs[4] = C(0)

local F = function(x)
    return V.new({x[1] * x[4] - x[2] * x[3],
                  x[1] * x[3] - x[2] * x[2],
                  x[2] * x[4] - x[3] * x[3],})
end

local sel_x = 1

local size = {}
size[1] = 15
size[2] = 12
size[3] = 9
size[4] = 6

local colors = {}
colors[1] = {1, 0, 0}
colors[2] = {0, 1, 0}
colors[3] = {0, 0, 1}
colors[4] = {1, 1, 1}

function love.update(dt)
    if love.keyboard.isDown("escape") then
        love.event.quit()
    end

    local dx, dy = 0, 0
    if love.keyboard.isDown("right") then dx = dx + 1 end
    if love.keyboard.isDown("left") then dx = dx - 1 end
    if love.keyboard.isDown("up") then dy = dy + 1 end
    if love.keyboard.isDown("down") then dy = dy - 1 end
    xs[sel_x] = xs[sel_x] + dt * C(dx, dy)
end

function love.keypressed(key, scancode, isrepeat)
    if key == "1" then sel_x = 1 end
    if key == "2" then sel_x = 2 end
    if key == "3" then sel_x = 3 end
    if key == "4" then sel_x = 4 end
end

function love.draw()
    love.graphics.setColor(colors[sel_x])
    love.graphics.print(sel_x, 0, 0)

    love.graphics.setColor(1, 1, 1)
    local F_x = F(xs)
    love.graphics.print(V.to_string(F_x), 0, 10)

    for i = 1, #xs do
        local sx = sw/2 + 100 * xs[i][1]
        local sy = sh/2 - 100 * xs[i][2]
        love.graphics.setPointSize(size[i])
        love.graphics.setColor(colors[i])
        love.graphics.points(sx, sy)
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.setPointSize(1)
    love.graphics.points(sw/2, sh/2)
    love.graphics.points(sw/2 + 100, sh/2)
    love.graphics.points(sw/2, sh/2 + 100)
    love.graphics.points(sw/2 - 100, sh/2)
    love.graphics.points(sw/2, sh/2 - 100)
end