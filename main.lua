local C, V, M = unpack(require "vector")
local S = require "symbol"

local sw, sh = love.graphics.getDimensions()

local n_var = 3
local x_v = {}
x_v[1] = C(0)
x_v[2] = C(0)
x_v[3] = C(0)

local F = function(x)
    return V{x_v[1] - x_v[2] * x_v[3],
             x_v[1] * x_v[3] - x_v[2] * x_v[2],
             x_v[2] - x_v[3] * x_v[3]}
end

local vars = {"x1", "x2", "x3"}
local vars_cpx = {"y1", "z1", "y2", "z2", "y3", "z3"}
local vars_real = {"y1", "y2", "y3"}
local vars_imag = {"z1", "z2", "z3"}
local vars_cpx_to_real = {x1={"y1", "z1"}, x2={"y2", "z2"}, x3={"y3", "z3"}}

local x_s = {}
for k, v in ipairs(vars) do x_s[k] = S(v) end

local n_eq = 3
local f_s = {}
f_s[1] = x_s[1] - x_s[2]*x_s[3]
f_s[2] = x_s[1]*x_s[3] - x_s[2]*x_s[2]
f_s[3] = x_s[2] - x_s[3]*x_s[3]

local f_real_s = {}
for i = 1, n_eq do
    local real_part, imag_part = f_s[i]:cpx_to_real(vars_cpx_to_real)
    table.insert(f_real_s, real_part:normal())
    table.insert(f_real_s, imag_part:normal())
end

local g_s = S()
for i = 1, 2*n_eq do
    g_s = g_s + f_real_s[i]^2
end
g_s = g_s:normal()

local g_grad_s = {}
for k, v in ipairs(vars_cpx) do g_grad_s[v] = g_s:der(v):normal() end

local g_hess_s = {}
for k1, v1 in ipairs(vars_cpx) do
    g_hess_s[v1] = {}
    for k2, v2 in ipairs(vars_cpx) do
        g_hess_s[v1][v2] = g_grad_s[v1]:der(v2):normal()
    end
end

local sel_x = 1

local size = {}
size[1] = 15
size[2] = 12
size[3] = 9

local colors = {}
colors[1] = {1, 0, 0}
colors[2] = {0, 1, 0}
colors[3] = {0, 0, 1}

local t = 0
function love.update(dt)
    if love.keyboard.isDown("escape") then
        love.event.quit()
    end

    local dx, dy = 0, 0
    if love.keyboard.isDown("right") then dx = dx + 1 end
    if love.keyboard.isDown("left") then dx = dx - 1 end
    if love.keyboard.isDown("up") then dy = dy + 1 end
    if love.keyboard.isDown("down") then dy = dy - 1 end
    x_v[sel_x] = x_v[sel_x] + 0.1 * dt * C(dx, dy)

    for k = 1, 10 do
        local vars_v = {}
        for i = 1, n_var do
            vars_v[vars_real[i]] = x_v[i][1]
            vars_v[vars_imag[i]] = x_v[i][2]
        end

        local h_0 = V()
        for i = 1, n_var do if i ~= sel_x then
            table.insert(h_0, 0)
            table.insert(h_0, 0)
        end end

        local b = V()
        for i = 1, n_var do if i ~= sel_x then
            table.insert(b, g_grad_s[vars_real[i]]:eval(vars_v))
            table.insert(b, g_grad_s[vars_imag[i]]:eval(vars_v))
        end end

        local A = M()
        for i = 1, n_var do if i ~= sel_x then
            local real_row = {}
            local imag_row = {}
            for j = 1, n_var do if j ~= sel_x then
                table.insert(real_row, g_hess_s[vars_real[i]][vars_real[j]]:eval(vars_v))
                table.insert(real_row, g_hess_s[vars_real[i]][vars_imag[j]]:eval(vars_v))
                table.insert(imag_row, g_hess_s[vars_imag[i]][vars_real[j]]:eval(vars_v))
                table.insert(imag_row, g_hess_s[vars_imag[i]][vars_imag[j]]:eval(vars_v))
            end end
            table.insert(A, real_row)
            table.insert(A, imag_row)
        end end

        local h = M.conj_grad(A, b, h_0)
        print(b)

        local step = 0.1
        local j = 1
        for i = 1, n_var do if i ~= sel_x then
            x_v[i] = C(x_v[i][1] - step*h[j], x_v[i][2] - step*h[j+1])
            j = j + 2
        end end
    end
end

function love.keypressed(key, scancode, isrepeat)
    if key == "1" then sel_x = 1 end
    if key == "2" then sel_x = 2 end
    if key == "3" then sel_x = 3 end
end

function love.draw()
    love.graphics.setColor(colors[sel_x])
    love.graphics.print(sel_x, 0, 0)

    do
        -- love.graphics.setColor(1, 1, 1)
        -- local F_x = F(xs)
        -- love.graphics.print(V.to_string(F_x), 0, 10)
        local vars_v = {}
        for i = 1, n_var do
            vars_v[vars_real[i]] = x_v[i][1]
            vars_v[vars_imag[i]] = x_v[i][2]
        end

        love.graphics.setColor(1, 1, 1)
        love.graphics.print(g_s:eval(vars_v), 0, 10)
        love.graphics.print(g_s:der("y1"):eval(vars_v), 0, 20)
        love.graphics.print(g_s:der("y2"):eval(vars_v), 0, 30)
        love.graphics.print(g_s:der("y3"):eval(vars_v), 0, 40)
        love.graphics.print(g_s:der("z2"):eval(vars_v), 200, 30)
        love.graphics.print(g_s:der("z1"):eval(vars_v), 200, 20)
        love.graphics.print(g_s:der("z3"):eval(vars_v), 200, 40)
    end

    for i = 1, #x_v do
        local sx = sw/2 + 100 * x_v[i][1]
        local sy = sh/2 - 100 * x_v[i][2]
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