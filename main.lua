local C, V, M = unpack(require "vector")

local sw, sh = love.graphics.getDimensions()

local n_var = 3
local x = V{C(0.5, math.sqrt(3)/2), C(0), C(0), C(0)}

local sel = 1
local free = false

local size = {}
size[1] = 15
size[2] = 12
size[3] = 9
size[4] = 6

local colors = {}
colors[1] = {1, 0.2, 0.2}
colors[2] = {0.2, 1, 0.2}
colors[3] = {0.2, 0.2, 1}
colors[4] = {1, 1, 1}

-- local n_eq = 1
-- local F = function(x) return V{x[1]*x[1] - x[2]*x[2]} end

-- local n_eq = 3
-- local F = function(x)
--     return V{x[1] * x[4] - x[2] * x[3],
--              x[1] * x[3] - x[2] * x[2],
--              x[2] * x[4] - x[3] * x[3]}
-- end

local n_eq = 1
local F = function(x)
    return V{x[1]^3 + x[2]^3 + x[3]^3 + 1}
end

local Dt
function love.update(dt)
    if love.keyboard.isDown("escape") then
        love.event.quit()
    end

    Dt = dt

    local dx, dy = 0, 0
    if love.keyboard.isDown("right") then dx = dx + 1 end
    if love.keyboard.isDown("left") then dx = dx - 1 end
    if love.keyboard.isDown("up") then dy = dy + 1 end
    if love.keyboard.isDown("down") then dy = dy - 1 end
    x[sel] = x[sel] + 0.5 * dt * C(dx, dy)

    if not free then
        local F_x = F(x)
        local norm_F_x = 0; for i = 1, n_eq do norm_F_x = norm_F_x + F_x[i]:modulus2() end
        local F_y, norm_F_y
        for i = 1, 100 do
            local y = x:copy()

            for j = 1, n_var do if j ~= sel then
                local a = 2 * math.pi * love.math.random()
                local r = norm_F_x * love.math.random()
                y[j] = y[j] + 0.1 * C(r * math.cos(a), r * math.sin(a))
            end end
            
            F_y = F(y)
            norm_F_y = 0; for j = 1, n_eq do norm_F_y = norm_F_y + F_y[j]:modulus2() end
            if norm_F_y < norm_F_x then
                x = y
                norm_F_x = norm_F_y
            end
        end
    end
end

function love.keypressed(key, scancode, isrepeat)
    if key == "1" then sel = 1 end
    if key == "2" then sel = 2 end
    if key == "3" then sel = 3 end
    if key == "4" then sel = 4 end
    if key == "space" then free = not free end
end

love.graphics.setBackgroundColor(0.1, 0.1, 0.1)

function love.draw()
    love.graphics.setColor(colors[sel])
    love.graphics.print(sel, 0, 0)

    love.graphics.setColor(1, 1, 1)
    -- love.graphics.print(1/Dt, 0, 10)
    -- love.graphics.print(tostring(F(x)), 0, 20)
    -- love.graphics.print(tostring(x[1]), 0, 30)
    -- love.graphics.print(tostring(x[2]), 0, 40)

    for i = 1, n_var do
        local sx = sw/2 + 100 * x[i][1]
        local sy = sh/2 - 100 * x[i][2]
        love.graphics.setColor(colors[i])
        -- love.graphics.setPointSize(size[i])
        -- love.graphics.points(sx, sy)
        love.graphics.circle("fill", sx, sy, size[i], 4)
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.setPointSize(2)
    love.graphics.points(sw/2, sh/2)
    love.graphics.points(sw/2 + 100, sh/2)
    love.graphics.points(sw/2, sh/2 + 100)
    love.graphics.points(sw/2 - 100, sh/2)
    love.graphics.points(sw/2, sh/2 - 100)
end