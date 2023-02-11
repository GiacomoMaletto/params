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
    s = s or {}
    if type(s) == "table" then setmetatable(s, S.mt) end
    return s
end

setmetatable(S, {__call = function(self, s) return S.new(s) end})








function S.der(e, v)
    if S.is_empty(e) then error()
    elseif S.is_num(e) then return 0
    elseif S.is_var(e) then return v == e and 1 or 0
    elseif S.is_add(e) then
        return {"+", S.der(S.fst(e), v), S.der(S.snd(e), v)}
    elseif S.is_sub(e) then
        return {"-", S.der(S.fst(e), v), S.der(S.snd(e), v)}
    elseif S.is_mul(e) then
        local f = S.fst(e)
        local g = S.snd(e)
        local fp = S.der(f, v)
        local gp = S.der(g, v)
        return {"+", {"*", fp, g}, {"*", f, gp}}
    elseif S.is_pow(e) then
        local f = S.fst(e)
        local n = S.snd(e)
        local fp = S.der(f, v)
        return {"*", n, {"*", {"^", f, n - 1}, fp}}
    end
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
        if S.is_num(f) then
            mons[#mons].scalar = mons[#mons].scalar * f
        elseif S.is_var(f) then
            mons[#mons][f] = mons[#mons][f] + 1
        elseif S.is_mul(f) then
            insert(S.fst(f))
            insert(S.snd(f))
        else error(f[1]) end
    end

    -- searches for monomials
    local function scan(f)
        if S.is_num(f) or S.is_var(f) or S.is_mul(f) then
            table.insert(mons, deep_copy(mon_default))
            insert(f)
        elseif S.is_add(f) or S.is_sub(f) then
            scan(S.fst(f))
            scan(S.snd(f))
        elseif S.is_pow(f) then error() end
    end

    scan(simple)

    -- adds equal monomials
    local summed = {}
    for i, m in ipairs(mons) do
        local m_eq_some = false
        for j, s in ipairs(summed) do
            local m_eq_s = true
            for _, v in ipairs(vars) do
                if not (s[v] == m[v]) then m_eq_s = false; break end
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
            elseif s[v] == 1 then mon_s = S.mul(mon_s, v)
            elseif s[v] > 0 then mon_s = S.mul(mon_s, S.pow(v, s[v])) end
        end
        result = result + mon_s
        ::continue::
    end

    return result
end

function S.distr(e)
    local function helper(f)
        if S.is_empty(f) or S.is_num(f) or S.is_var(f) then return f, false
        elseif S.is_mul(f) and S.is_add_or_sub(S.snd(f)) then
            local f1 = helper({"*", S.fst(f), S.fst(S.snd(f))})
            local f2 = helper({"*", S.fst(f), S.snd(S.snd(f))})
            return S({S.op(S.snd(f)), f1, f2}), true
        elseif S.is_mul(f) and S.is_add_or_sub(S.fst(f)) then
            return helper(S({"*", S.snd(f), S.fst(f)}))
        elseif S.is_bin(f) then
            local fst, fst_b = helper(S.fst(f))
            local snd, snd_b = helper(S.snd(f))
            return S({S.op(f), fst, snd}), fst_b or snd_b
        end
    end
    local b = true
    while b do
        e, b = helper(e)
    end
    return e
end

function S.vars(e)
    local result = {}
    local function helper(f)
        if S.is_empty(f) or S.is_num(f) then
        elseif S.is_var(f) then Set.insert(result, f)
        elseif S.is_bin(f) then helper(S.fst(f)); helper(S.snd(f)) end
    end
    helper(e)
    return result
end

function S.to_string(e)
    if S.is_empty(e) then return "()"
    elseif S.is_num(e) then return tostring(e)
    elseif S.is_var(e) then return e
    elseif S.is_add(e) or S.is_sub(e) then
        return "(" .. S.to_string(S.fst(e)) .. " " .. S.op(e) .. " " .. S.to_string(S.snd(e)) .. ")"
    elseif S.is_mul(e) or S.is_pow(e) then
        return "(" .. S.to_string(S.fst(e)) .. S.op(e) .. S.to_string(S.snd(e)) .. ")"
    end
end

S.mt.__tostring = S.to_string

function S.pow_to_mul(e)
    if S.is_empty(e) then return S()
    elseif S.is_num(e) or S.is_var(e) then return S(e)
    elseif S.is_pow(e) then
        local b = S.fst(e)
        local n = S.snd(e)
        if n == 1 then return S(b)
        else return S({"*", b, S.pow_to_mul({"^", b, n - 1})}) end
    elseif S.is_bin(e) then
        return S({S.op(e), S.pow_to_mul(S.fst(e)), S.pow_to_mul(S.snd(e))})
    end
end

function S.cpx_to_real(e, t)
    if S.is_empty(e) then return {}
    elseif S.is_real(e) then return e, e
    elseif S.is_cpx(e) then return e[1], e[2]
    elseif S.is_var(e) then return t[e][1], t[e][2]
    elseif S.is_add(e) then
        local r1, i1 = S.cpx_to_real(S.fst(e), t)
        local r2, i2 = S.cpx_to_real(S.snd(e), t)
        return {"+", r1, r2}, {"+", i1, i2}
    elseif S.is_sub(e) then
        local r1, i1 = S.cpx_to_real(S.fst(e), t)
        local r2, i2 = S.cpx_to_real(S.snd(e), t)
        return {"-", r1, r2}, {"-", i1, i2}
    elseif S.is_mul(e) then
        local r1, i1 = S.cpx_to_real(S.fst(e), t)
        local r2, i2 = S.cpx_to_real(S.snd(e), t)
        return {"-", {"*", r1, r2}, {"*", i1, i2}}, {"+", {"*", r1, i2}, {"*", r2, i1}}
    elseif S.is_pow(e) then return S.cpx_to_real(S.pow_to_mul(e), t) end
end

function S.eval(e, x)
    if S.is_empty(e) then error()
    elseif S.is_num(e) then return e
    elseif S.is_var(e) then return x[e]
    elseif S.is_add(e) then return S.eval(S.fst(e), x) + S.eval(S.snd(e), x)
    elseif S.is_sub(e) then return S.eval(S.fst(e), x) - S.eval(S.snd(e), x)
    elseif S.is_mul(e) then return S.eval(S.fst(e), x) * S.eval(S.snd(e), x)
    elseif S.is_pow(e) then return S.eval(S.fst(e), x) ^ S.eval(S.snd(e), x) end
end

function S.is_empty(e)
    return type(e) == "table" and #e == 0
end

function S.is_num(e)
    return C.is_scalar(e)
end

function S.is_real(e)
    return C.is_real(e)
end

function S.is_cpx(e)
    return C.is_complex(e)
end

function S.is_var(e)
    return type(e) == "string"
end

function S.is_add(e)
    return type(e) == "table" and e[1] == "+"
end

function S.is_sub(e)
    return type(e) == "table" and e[1] == "-"
end

function S.is_add_or_sub(e)
    return S.is_add(e) or S.is_sub(e)
end

function S.is_mul(e)
    return type(e) == "table" and e[1] == "*"
end

function S.is_pow(e)
    return type(e) == "table" and e[1] == "^"
end

function S.is_bin(e)
    return type(e) == "table" and (e[1] == "+" or e[1] == "-" or e[1] == "*" or e[1] == "^")
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

function S.add(e, f)
    if S.is_empty(e) and S.is_empty(f) then return S()
    elseif S.is_empty(e) and not S.is_empty(f) then return f
    elseif not S.is_empty(e) and S.is_empty(f) then return e
    else return S({"+", e, f}) end
end

S.mt.__add = S.add

function S.mul(e, f)
    if S.is_empty(e) and S.is_empty(f) then return S()
    elseif S.is_empty(e) and not S.is_empty(f) then return f
    elseif not S.is_empty(e) and S.is_empty(f) then return e
    else return S({"*", e, f}) end
end

S.mt.__mul = S.mul

function S.pow(e, n)
    if S.is_empty(e) then return S()
    else return S({"^", e, n}) end
end

S.mt.__pow = S.pow

do
    local f = S {"-", {"*", "x0", "x3"}, {"*", "x1", "x2"}}
    local g = S {"-", {"*", "x0", "x2"}, {"*", "x1", "x1"}}
    local h = S {"-", {"*", "x1", "x3"}, {"*", "x2", "x2"}}
    local F = S.normal(f * f + g * g + h * h)
    print(F)
end

return S