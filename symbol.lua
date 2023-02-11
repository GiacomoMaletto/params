local C, V, M = unpack(require "vector")

local Set = {}
function Set.insert(s, v)
    for i = 1, #s do
        if s[i] == v then return false end
    end
    table.insert(s, v)
    return true
end


local S = {}
S.mt = {}

function S.new(s)
    if getmetatable(s) == S.mt then return s end
    local result
    if s == nil then result = {}
    elseif type(s) == "number" or type(s) == "string" then result = {s}
    elseif type(s) == "table" then result = s
    else error() end
    setmetatable(result, S.mt)
    return result
end

setmetatable(S, {__call = function(self, s) return S.new(s) end})

S.mt.__index = S

function S.copy(e)
    return S(deep_copy(e))
end

function S.num(e)
    return e[1]
end

function S.var(e)
    return e[1]
end

function S.op(e)
    return e[1]
end

function S.fst(e)
    return S(e[2])
end

function S.snd(e)
    return S(e[3])
end

-- empty: some operations are undefined on it (ex. evaluation)
-- but it is useful because addition and multiplication are defined st
-- S() + e = e
-- S() * e = e
-- so extended sums and products are easier to define
function S.is_empty(e)
    return type(e) == "table" and #e == 0
end

function S.is_num(e)
    return #e == 1 and C.is_scalar(e[1])
end

function S.is_real(e)
    return #e == 1 and C.is_real(e[1])
end

function S.is_cpx(e)
    return #e == 1 and C.is_complex(e[1])
end

function S.is_var(e)
    return #e == 1 and type(e[1]) == "string"
end

function S.is_add(e)
    return #e == 3 and e[1] == "+"
end

function S.is_sub(e)
    return #e == 3 and e[1] == "-"
end

function S.is_add_or_sub(e)
    return e:is_add() or e:is_sub()
end

function S.is_mul(e)
    return #e == 3 and e[1] == "*"
end

-- only power where the exponent is a non-negative integer are allowed
function S.is_pow(e)
    return #e == 3 and e[1] == "^"
end

function S.is_bin(e)
    return e:is_add() or e:is_sub() or e:is_mul() or e:is_pow()
end

-- side effect: changes the metatable of its arguments
function S.add(e, f)
    e, f = S(e), S(f)
    if e:is_empty() and f:is_empty() then return S()
    elseif e:is_empty() and not f:is_empty() then return f
    elseif not e:is_empty() and f:is_empty() then return e
    else return S{"+", e, f} end
end

S.mt.__add = S.add

-- side effect: changes the metatable of its arguments
function S.sub(e, f)
    e, f = S(e), S(f)
    if e:is_empty() and f:is_empty() then return S()
    elseif e:is_empty() and not f:is_empty() then return S{"*", S(-1), f}
    elseif not e:is_empty() and f:is_empty() then return e
    else return S{"-", e, f} end
end

S.mt.__sub = S.sub

-- side effect: changes the metatable of its arguments
function S.mul(e, f)
    e, f = S(e), S(f)
    if e:is_empty() and f:is_empty() then return S()
    elseif e:is_empty() and not f:is_empty() then return f
    elseif not e:is_empty() and f:is_empty() then return e
    else return S{"*", e, f} end
end

S.mt.__mul = S.mul

-- side effect: changes the metatable of its arguments
function S.pow(e, n)
    e, n = S(e), S(n)
    if e:is_empty() then return S()
    else return S{"^", e, n} end
end

S.mt.__pow = S.pow

function S.bin(o, e, f)
    if o == "+" then return e + f
    elseif o == "-" then return e - f
    elseif o == "*" then return e * f
    elseif o == "^" then return e ^ f end
end

function S.to_string(e)
    if e:is_empty() then return "()"
    elseif e:is_num() then return tostring(e:num())
    elseif e:is_var() then return e:var()
    elseif e:is_add_or_sub() then
        return "(" .. e:fst():to_string() .. " " .. e:op() .. " " .. e:snd():to_string() .. ")"
    elseif e:is_mul() or e:is_pow() then
        return "(" .. e:fst():to_string() .. e:op() .. e:snd():to_string() .. ")"
    end
end

S.mt.__tostring = S.to_string

function S.eval(e, x)
    if e:is_empty() then error()
    elseif e:is_num() then return e:num()
    elseif e:is_var() then return x[e:var()]
    elseif e:is_add() then return e:fst():eval(x) + e:snd():eval(x)
    elseif e:is_sub() then return e:fst():eval(x) - e:snd():eval(x)
    elseif e:is_mul() then return e:fst():eval(x) * e:snd():eval(x)
    elseif e:is_pow() then return e:fst():eval(x) ^ e:snd():eval(x) end
end

function S.vars(e)
    local result = {}
    local function helper(f)
        if f:is_empty() or f:is_num() then
        elseif f:is_var() then Set.insert(result, f:var())
        elseif f:is_bin() then helper(f:fst()); helper(f:snd()) end
    end
    helper(e)
    table.sort(result)
    return result
end

function S.pow_to_mul(e)
    if e:is_empty() then return S()
    elseif e:is_num() then return S(e:num())
    elseif e:is_var() then return S(e:var())
    elseif e:is_pow() then
        local b = e:fst():pow_to_mul()
        local n = e:snd():num()
        local result = S()
        for i = 1, n do
            result = result * b
        end
        return result
    elseif e:is_bin() then
        return S.bin(e:op(), e:fst():pow_to_mul(), e:snd():pow_to_mul())
    end
end

-- can be made faster
function S.cpx_to_real(e, t)
    if e:is_empty() then return S(), S()
    elseif e:is_real() then return S(e:num()), S(e:num())
    elseif e:is_cpx() then return S(e:num()[1]), S(e:num()[2])
    elseif e:is_var() then return S(t[e:var()][1]), S(t[e:var()][2])
    elseif e:is_add() then
        local r1, i1 = e:fst():cpx_to_real(t)
        local r2, i2 = e:snd():cpx_to_real(t)
        return r1 + r2, i1 + i2
    elseif e:is_sub() then
        local r1, i1 = e:fst():cpx_to_real(t)
        local r2, i2 = e:snd():cpx_to_real(t)
        return r1 - r2, i1 - i2
    elseif e:is_mul() then
        local r1, i1 = e:fst():cpx_to_real(t)
        local r2, i2 = e:snd():cpx_to_real(t)
        return r1*r2 - i1*i2, r1*i2 + r2*i1
    elseif e:is_pow() then return e:pow_to_mul():cpx_to_real(t) end
end

function S.distr(e)
    local function helper(f)
        if f:is_empty() or f:is_num() or f:is_var() then return f, false
        elseif f:is_mul() and f:fst():is_add_or_sub() then
            local f1 = helper(f:fst():fst() * f:snd())
            local f2 = helper(f:fst():snd() * f:snd())
            return S.bin(f:fst():op(), f1, f2), true
        elseif f:is_mul() and f:snd():is_add_or_sub() then
            local f1 = helper(f:fst() * f:snd():fst())
            local f2 = helper(f:fst() * f:snd():snd())
            return S.bin(f:snd():op(), f1, f2), true
        elseif f:is_bin() then
            local fst, fst_b = helper(f:fst())
            local snd, snd_b = helper(f:snd())
            return S.bin(f:op(), fst, snd), fst_b or snd_b
        end
    end
    local b = true
    while b do
        e, b = helper(e)
    end
    return e
end

function S.normal(e)
    -- variable names
    local vars = S.vars(e)
    
    -- default monomial
    local mon_default = {}
    for k, v in ipairs(vars) do
        mon_default[v] = 0
        mon_default.scalar = 1
    end

    -- monomial table
    local mons = {}

    -- remove powers, use distributivity
    local simple = S.distr(S.pow_to_mul(e))

    -- adds monomials
    local function insert(f)
        if f:is_num() then
            mons[#mons].scalar = mons[#mons].scalar * f:num()
        elseif f:is_var() then
            mons[#mons][f:var()] = mons[#mons][f:var()] + 1
        elseif f:is_mul() then
            insert(f:fst())
            insert(f:snd())
        else error() end
    end

    -- searches for monomials
    local function scan(f)
        if f:is_num() or f:is_var() or f:is_mul() then
            table.insert(mons, deep_copy(mon_default))
            insert(f)
        elseif f:is_add_or_sub() then
            scan(f:fst())
            scan(f:snd())
        elseif f:is_pow() then error() end
    end

    scan(simple)

    -- adds equal monomials
    local summed = {}
    for i, m in ipairs(mons) do
        local m_eq_some = false
        for j, s in ipairs(summed) do
            local m_eq_s = true
            for _, v in ipairs(vars) do
                if s[v] ~= m[v] then m_eq_s = false; break end
            end
            if m_eq_s then
                s.scalar = s.scalar + m.scalar
                m_eq_some = true
                break
            end
        end
        if not m_eq_some then table.insert(summed, m) end
    end

    -- create the final equation
    local result = S()
    for i, s in ipairs(summed) do
        local mon_s
        if s.scalar == 0 then goto continue
        elseif s.scalar == 1 then mon_s = S()
        else mon_s = S(s.scalar) end
        for _, v in ipairs(vars) do
            if s[v] == 0 then
            elseif s[v] == 1 then mon_s = mon_s * S(v)
            elseif s[v] > 0 then mon_s = mon_s * S(v)^S(s[v]) end
        end
        result = result + mon_s
        ::continue::
    end

    return result
end

-- v can be either a string or a symbolic variable
function S.der(e, v)
    if e:is_empty() then error()
    elseif e:is_num() then return S(0)
    elseif e:is_var() then return S(v):var() == e:var() and S(1) or S(0)
    elseif e:is_add() then
        return e:fst():der(v) + e:snd():der(v)
    elseif e:is_sub() then
        return e:fst():der(v) - e:snd():der(v)
    elseif e:is_mul() then
        local f = e:fst()
        local g = e:snd()
        local fp = f:der(v)
        local gp = g:der(v)
        return fp * g + f * gp
    elseif e:is_pow() then
        local f = e:fst()
        local n = e:snd():num()
        local fp = f:der(v)
        return n * f^(n-1) * fp
    end
end


-- example usage
-- do
--     local x0, x1, x2, x3 = S("x0"), S("x1"), S("x2"), S("x3")
--     local f = x0*x3 - x1*x2
--     local g = x0*x2 - x1*x1
--     local h = x1*x3 - x2*x2
--     local F = f^2 + g^2 + h^2
--     print(F:normal())
--     print(F:der(x0):normal())
-- end

return S