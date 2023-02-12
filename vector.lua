local C = {}
local V = {}
local M = {}

C.mt = {}
V.mt = {}
M.mt = {}

function shallow_copy(orig)
    local copy = {}
    for orig_key, orig_value in pairs(orig) do
        copy[orig_key] = orig_value
    end
    return copy
end

function deep_copy(orig, copies)
    copies = copies or {}
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for orig_key, orig_value in next, orig, nil do
                copy[deep_copy(orig_key, copies)] = deep_copy(orig_value, copies)
            end
            setmetatable(copy, deep_copy(getmetatable(orig), copies))
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end


-- side effect: can change the metatable of its argument
function C.new(x, y)
    local result
    if x == nil then result = {}
    elseif type(x) == "number" and y == nil then result = {x, 0}
    elseif type(x) == "number" and type(y) == "number" then result = {x, y}
    elseif type(x) == "table" then result = x
    else error() end
    setmetatable(result, C.mt)
    return result
end

setmetatable(C, {__call = function(self, x, y) return C.new(x, y) end})

C.mt.__index = C

function C.copy(c)
    return C(shallow_copy(c))
end

function C.is_complex(x)
    return getmetatable(x) == C.mt
end

function C.is_real(x)
    return type(x) == "number"
end

function C.is_scalar(x)
    return C.is_complex(x) or C.is_real(x)
end

function C.is_zero(x)
    if C.is_real(x) then return x == 0
    elseif C.is_complex(x) then return x[1] == 0, x[2] == 0
    else error() end
end

function C.add(c1, c2)
    local result = C()
    result[1] = c1[1] + c2[1]
    result[2] = c1[2] + c2[2]
    return result
end

C.mt.__add = C.add

function C.sub(c1, c2)
    local result = C()
    result[1] = c1[1] - c2[1]
    result[2] = c1[2] - c2[2]
    return result
end

C.mt.__sub = C.sub

function C.mul(c1, c2)
    local result = C()
    result[1] = c1[1]*c2[1] - c1[2]*c2[2]
    result[2] = c1[1]*c2[2] - c1[2]*c2[1]
    return result
end

function C.mulr(r, c)
    local result = C()
    result[1] = r*c[1]
    result[2] = r*c[2]
    return result
end

C.mt.__mul = function(a, b)
    if C.is_complex(a) and C.is_complex(b) then return C.mul(a, b) end
    if C.is_real(a) and C.is_complex(b) then return C.mulr(a, b) end
    if C.is_complex(a) and C.is_real(b) then return C.mulr(b, a) end
    error()
end

function C.pow(c, n)
    local result = C(1)
    for i = 1, n do result = result * c end
    return result
end

C.mt.__pow = C.pow

function C.to_string(c)
    return string.format("%04f", c[1]) .. " + " .. string.format("%04f", c[2]) .. "i"
end

C.mt.__tostring = C.to_string

-- side effect: can change the metatable of its argument
function V.new(v)
    v = v or {}
    setmetatable(v, V.mt)
    return v
end

setmetatable(V, {__call = function(self, v) return V.new(v) end})

V.mt.__index = V

function V.copy(v)
    return V(deep_copy(v))
end

function V.is_vector(x)
    return getmetatable(x) == V.mt
end

function V.add(v1, v2)
    local result = V()
    for i = 1, #v1 do
        result[i] = v1[i] + v2[i]
    end
    return result
end

V.mt.__add = V.add

function V.sub(v1, v2)
    local result = V()
    for i = 1, #v1 do
        result[i] = v1[i] - v2[i]
    end
    return result
end

V.mt.__sub = V.sub

function V.mul(c, v)
    local result = V()
    for i = 1, #v do
        result[i] = c * v[i]
    end
    return result
end

function V.dot(v1, v2)
    local result = 0
    for i = 1, #v1 do
        result = result + v1[i] * v2[i]
    end
    return result
end

V.mt.__mul = function(a, b)
    if V.is_vector(a) and V.is_vector(b) then return V.dot(a, b) end
    if C.is_scalar(a) and V.is_vector(b) then return V.mul(a, b) end
    error()
end

function V.length(v)
    return math.sqrt(v * v)
end

function V.to_string(v)
    local str = "("
    for i = 1, #v-1 do
        str = str .. tostring(v[i]) .. ", "
    end
    str = str .. tostring(v[#v]) .. ")"
    return str
end

V.mt.__tostring = V.to_string

-- side effect: can change the metatable of its argument
function M.new(m)
    m = m or {}
    setmetatable(m, M.mt)
    return m
end

setmetatable(M, {__call = function(self, m) return M.new(m) end})

M.mt.__index = M

function M.copy(m)
    return M(deep_copy(m))
end

function M.is_matrix(m)
    return getmetatable(m) == M.mt
end

function M.height(m)
    return #m
end

function M.width(m)
    if m:height() == 0 then
        return 0
    else
        return #m[1]
    end
end

function M.muls(s, m)
    local result = M()
    for i = 1, m:height() do
        result[i] = {}
        for j = 1, m:width() do
            result[i][j] = s * m[i][j]
        end
    end
    return result
end

function M.mulv(m, v)
    local result = V()
    for i = 1, m:height() do
        result[i] = 0
        for j = 1, #v do
            result[i] = result[i] + m[i][j] * v[j]
        end
    end
    return result
end

function M.mulm(m1, m2)
    local result = M()
    for i = 1, m1:height() do
        result[i] = {}
        for j = 1, m2:width() do
            result[i][j] = 0
            for k = 1, m2:height() do
                result[i][j] = result[i][j] + m1[i][k] * m2[k][j]
            end
        end
    end
    return result
end

M.mt.__mul = function(a, b)
    if M.is_matrix(a) and M.is_matrix(b) then return M.mulm(a, b) end
    if M.is_matrix(a) and V.is_vector(b) then return M.mulv(a, b) end
    if C.is_scalar(a) and M.is_matrix(b) then return M.muls(a, b) end
    error()
end

function M.to_string(m)
    local str = "("
    for i = 1, m:height() do
        str = str .. "("
        for j = 1, m:width() do
            str = str .. tostring(m[i][j]) .. ", "
        end
        str = str:sub(1, -3)
        str = str .. "),\n"
    end
    str = str:sub(1, -3)
    str = str .. ")"
    return str
end

M.mt.__tostring = M.to_string

function M.minor(m, i, j) -- i row, j column
    local result = M()
    for k = 1, m:height() do
        if k ~= i then
            table.insert(result, {})
            for h = 1, m:width() do
                if h ~= j then 
                    table.insert(result[#result], m[k][h])
                end
            end
        end
    end
    return result
end

function M.cramer(m)
    if m:height() ~= m:width() then
        error()
    elseif m:height() == 1 then
        return m[1][1]
    else 
        local result = 0
        for i = 1, m:height() do
            result = result + (-1)^(i+1) * m[i][1] * m:minor(i, 1):cramer()
        end
        return result
    end
end

function M.conj_grad(A, b, x_0)
    local x = x_0:copy()
    local r = b - A * x;
    if math.sqrt(r * r) < 1e-8 then return x end
    local p = r;
    local rsold = r * r;

    local Ap, alpha, rsnew
    for i = 1, #b do
        Ap = A * p;
        alpha = rsold / (p * Ap);
        x = x + alpha * p;
        r = r - alpha * Ap;
        rsnew = r * r;
        if math.sqrt(rsnew) < 1e-8 then
            break
        end
        p = r + (rsnew / rsold) * p;
        rsold = rsnew;
    end
    return x

    -- x = x_0:copy()
    -- local r = b - A * x
    -- if r:length() < 1e-8 then return x end
    -- local p = r
    -- local alpha, beta, rp
    -- local i = 0
    -- while i < 100 do
    --     alpha = (r * r) / (p * (A * p))
    --     x = x + alpha * p
    --     rp = r - alpha * A * p
    --     if rp:length() < 1e-8 then return x end
    --     print(rp:length())
    --     beta = (rp * rp) / (r * r)
    --     p = rp + beta * p
    --     i = i + 1
    -- end
end

-- example usage
-- do
    -- local M = M{{1, 2, 3}, {-1, 1, 1}, {-1, 1, 3}}
    -- local v = V{1, 2, 3}
    -- print(M)
    -- print(M * v)
    -- print(M:det())

    -- local A = M{{4, 1}, {1, 3}}
    -- local b = V{1, 2}
    -- local x_0 = V{2, 1}
    -- local x = M.conj_grad(A, b, x_0)
    -- print(x)
-- end

return {C, V, M}