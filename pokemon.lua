--[[
╔══════════════════════════════════════════════════════════════════════════╗
║       🌿 POKÉMON WORLD - ULTRA REALISTIC SERVER SCRIPT v2.0 🌿           ║
║                                                                          ║
║  Cambios v2.0:                                                           ║
║  • Mapa GIGANTE (1200x1200 studs)                                        ║
║  • Hierba por TODO el mapa con variación natural                         ║
║  • Rocas completamente rediseñadas, moldeadas al suelo                   ║
║  • Flores detalladas tipo Pokémon                                        ║
║  • Montañas estilo Pokémon Diamond/Pearl con nieve real                  ║
║  • Montañas alejadas al borde del mundo                                  ║
║  • Corregido error aritmético (blockH nil)                               ║
╚══════════════════════════════════════════════════════════════════════════╝
--]]

local Workspace    = game:GetService("Workspace")
local Lighting     = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local Players      = game:GetService("Players")
local Terrain      = Workspace.Terrain

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURACIÓN DEL MUNDO GIGANTE
-- ═══════════════════════════════════════════════════════════════
local W = {
    SIZE_X    = 1800,
    SIZE_Z    = 1800,
    BASE_Y    = 0,
    SEED      = 73,
    MTN_START = 700,

    C = {
        G_BASE    = Color3.fromRGB(72,  148,  20),
        G_MID     = Color3.fromRGB(88,  168,  30),
        G_BRIGHT  = Color3.fromRGB(110, 190,  45),
        G_DARK    = Color3.fromRGB(48,  110,  12),
        G_WILD    = Color3.fromRGB(35,   95,   8),
        DIRT      = Color3.fromRGB(175, 138,  72),
        DIRT_D    = Color3.fromRGB(138, 100,  48),
        DIRT_L    = Color3.fromRGB(210, 175, 105),
        R_BASE    = Color3.fromRGB(138, 130, 118),
        R_DARK    = Color3.fromRGB( 88,  82,  75),
        R_LIGHT   = Color3.fromRGB(185, 175, 162),
        R_MOSS    = Color3.fromRGB( 95, 118,  72),
        M_BASE    = Color3.fromRGB( 95,  85,  75),
        M_ROCK    = Color3.fromRGB(125, 115, 102),
        M_MID     = Color3.fromRGB(158, 148, 135),
        M_HIGH    = Color3.fromRGB(195, 188, 178),
        M_SNOW    = Color3.fromRGB(248, 250, 255),
        M_SNOW2   = Color3.fromRGB(225, 235, 248),
        M_ICE     = Color3.fromRGB(210, 228, 248),
        W_DEEP    = Color3.fromRGB( 35, 105, 210),
        W_MID     = Color3.fromRGB( 55, 140, 230),
        W_SHALLOW = Color3.fromRGB( 90, 175, 245),
        W_FOAM    = Color3.fromRGB(215, 238, 255),
        T_TRUNK   = Color3.fromRGB( 95,  60,  25),
        T_BARK    = Color3.fromRGB(115,  78,  38),
        T_LEAF1   = Color3.fromRGB( 35, 128,  18),
        T_LEAF2   = Color3.fromRGB( 55, 158,  28),
        T_LEAF3   = Color3.fromRGB( 70, 175,  40),
        T_PINE    = Color3.fromRGB( 28, 100,  18),
        T_PINE2   = Color3.fromRGB( 45, 125,  28),
        F_RED     = Color3.fromRGB(228,  45,  45),
        F_PINK    = Color3.fromRGB(238, 130, 168),
        F_YELLOW  = Color3.fromRGB(252, 218,  35),
        F_BLUE    = Color3.fromRGB( 72, 118, 228),
        F_PURPLE  = Color3.fromRGB(158,  72, 218),
        F_WHITE   = Color3.fromRGB(245, 245, 242),
        F_ORANGE  = Color3.fromRGB(245, 135,  35),
        F_STEM    = Color3.fromRGB( 58, 115,  28),
        SAND      = Color3.fromRGB(228, 208, 145),
        SAND_D    = Color3.fromRGB(198, 172, 105),
        FOG       = Color3.fromRGB(185, 215, 240),
    },
}

-- ═══════════════════════════════════════════════════════════════
-- UTILIDADES
-- ═══════════════════════════════════════════════════════════════
local function rng(a, b)    return a + math.random() * (b - a) end
local function rngi(a, b)   return math.random(a, b) end
local function clamp(v,a,b) return math.max(a, math.min(b, v)) end
local function lerp(a,b,t)  return a + (b-a)*t end

local function lc(c1, c2, t)
    t = clamp(t, 0, 1)
    return Color3.new(lerp(c1.R,c2.R,t), lerp(c1.G,c2.G,t), lerp(c1.B,c2.B,t))
end

local function fnoise(x, z, oct, pers, lac, scale, seed)
    local val, amp, freq, maxV = 0, 1, 1, 0
    seed = seed or 0
    for i = 1, oct do
        val  = val  + math.noise(x/scale*freq + seed*0.13 + i*17.3,
                                 z/scale*freq + seed*0.13 + i*9.7) * amp
        maxV = maxV + amp
        amp  = amp  * pers
        freq = freq * lac
    end
    return val / maxV
end

local function groundH(x, z)
    local hX = W.SIZE_X * 0.5
    local hZ = W.SIZE_Z * 0.5
    local h  = fnoise(x, z, 5, 0.52, 2.1, 120, W.SEED) * 5.5
    local fx = clamp(math.min((x+hX)/120, (hX-x)/120), 0, 1)
    local fz = clamp(math.min((z+hZ)/120, (hZ-z)/120), 0, 1)
    return W.BASE_Y + h * fx * fz
end

local occupied = {}
local function isOcc(x, z, r)
    for _, p in ipairs(occupied) do
        local dx, dz = p.x-x, p.z-z
        if dx*dx + dz*dz < (p.r+r)*(p.r+r) then return true end
    end
    return false
end
local function markOcc(x, z, r)
    occupied[#occupied+1] = {x=x, z=z, r=r}
end

-- ═══════════════════════════════════════════════════════════════
-- FOLDERS
-- ═══════════════════════════════════════════════════════════════
local FW

local function mkFolder(name, parent)
    parent = parent or Workspace
    local old = parent:FindFirstChild(name)
    if old then old:Destroy() end
    local f = Instance.new("Folder")
    f.Name   = name
    f.Parent = parent
    return f
end

-- ═══════════════════════════════════════════════════════════════
-- HELPERS: Part / WedgePart
-- ═══════════════════════════════════════════════════════════════
local function mp(t)
    local p = Instance.new("Part")
    p.Anchored      = true
    p.CanCollide    = t.cc  ~= false
    p.CastShadow    = t.cs  ~= false
    p.TopSurface    = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Size          = t.sz  or Vector3.new(4,1,4)
    p.Color         = t.col or W.C.G_BASE
    p.Material      = t.mat or Enum.Material.SmoothPlastic
    p.Transparency  = t.tr  or 0
    p.Name          = t.n   or "P"
    if t.cf  then p.CFrame    = t.cf
    else          p.Position  = t.pos or Vector3.new(0,0,0) end
    p.Parent = t.par or FW
    return p
end

local function mw(t)
    local p = Instance.new("WedgePart")
    p.Anchored      = true
    p.CanCollide    = t.cc ~= false
    p.CastShadow    = true
    p.TopSurface    = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Size          = t.sz  or Vector3.new(4,4,4)
    p.Color         = t.col or W.C.M_ROCK
    p.Material      = t.mat or Enum.Material.Rock
    p.Name          = t.n   or "W"
    p.CFrame        = t.cf  or CFrame.new(0,0,0)
    p.Parent        = t.par or FW
    return p
end

-- ═══════════════════════════════════════════════════════════════
-- 1. ATMÓSFERA
-- ═══════════════════════════════════════════════════════════════
local function setupAtmosphere()
    for _, c in ipairs(Lighting:GetChildren()) do
        if c:IsA("Sky") or c:IsA("Atmosphere") or c:IsA("BloomEffect")
        or c:IsA("ColorCorrectionEffect") or c:IsA("DepthOfFieldEffect")
        or c:IsA("SunRaysEffect") then c:Destroy() end
    end
    Lighting.Brightness               = 2.8
    Lighting.ClockTime                = 13
    Lighting.GeographicLatitude       = 28
    Lighting.ShadowSoftness           = 0.25
    Lighting.Ambient                  = Color3.fromRGB(110,125,148)
    Lighting.OutdoorAmbient           = Color3.fromRGB(150,168,195)
    Lighting.EnvironmentDiffuseScale  = 0.75
    Lighting.EnvironmentSpecularScale = 0.45
    Lighting.FogEnd                   = 900
    Lighting.FogStart                 = 580
    Lighting.FogColor                 = W.C.FOG

    local atmo = Instance.new("Atmosphere")
    atmo.Density = 0.32; atmo.Offset = 0.15
    atmo.Color   = Color3.fromRGB(195,222,255)
    atmo.Decay   = Color3.fromRGB(105,145,210)
    atmo.Glare   = 0.28; atmo.Haze = 1.8
    atmo.Parent  = Lighting

    local bloom = Instance.new("BloomEffect")
    bloom.Intensity = 0.35; bloom.Size = 20; bloom.Threshold = 0.88
    bloom.Parent = Lighting

    local cc = Instance.new("ColorCorrectionEffect")
    cc.Brightness = 0.03; cc.Contrast = 0.14; cc.Saturation = 0.28
    cc.TintColor = Color3.fromRGB(255,252,248)
    cc.Parent = Lighting

    local sr = Instance.new("SunRaysEffect")
    sr.Intensity = 0.10; sr.Spread = 0.45; sr.Parent = Lighting

    print("✅ Atmósfera lista")
end

-- ═══════════════════════════════════════════════════════════════
-- 2. TERRENO BASE
-- ═══════════════════════════════════════════════════════════════
local function buildTerrain(TF)
    local TX = 100; local TZ = 100
    local tW = W.SIZE_X / TX; local tD = W.SIZE_Z / TZ
    local hX = W.SIZE_X * 0.5; local hZ = W.SIZE_Z * 0.5
    local n  = 0
    for ix = 1, TX do
        for iz = 1, TZ do
            local px = -hX + (ix-0.5)*tW
            local pz = -hZ + (iz-0.5)*tD
            local py = groundH(px,pz)
            local cn = math.noise(ix*0.28+3.1, iz*0.28+3.1)
            local col = cn > 0.18 and W.C.G_BRIGHT or (cn > -0.08 and W.C.G_MID or W.C.G_DARK)
            local mat = math.noise(ix*0.18+20, iz*0.18+20) > 0.05
                        and Enum.Material.Grass or Enum.Material.LeafyGrass
            mp({ n="T", sz=Vector3.new(tW+0.08,1.2,tD+0.08),
                 pos=Vector3.new(px, py-0.4, pz),
                 col=col, mat=mat, par=TF })
            n = n + 1
        end
        if ix % 12 == 0 then
            task.wait()
            print(string.format("   Terreno %d%%", math.floor(ix/TX*100)))
        end
    end
    mp({ n="Floor", sz=Vector3.new(W.SIZE_X+200,4,W.SIZE_Z+200),
         pos=Vector3.new(0, W.BASE_Y-5, 0),
         col=W.C.G_DARK, mat=Enum.Material.Grass, par=TF })
    print("✅ Terreno listo ("..n.." tiles)")
end

-- ═══════════════════════════════════════════════════════════════
-- 3. HIERBA  — cubre TODO el mapa gigante
-- ═══════════════════════════════════════════════════════════════
local function buildGrass(GF)
    -- Usamos Terrain de Roblox para un césped más natural que miles de partes rígidas.
    -- El folder GF se mantiene para compatibilidad con el flujo del generador.
    local hX = W.SIZE_X*0.5 - 8
    local hZ = W.SIZE_Z*0.5 - 8
    local step = 12
    local painted = 0

    for x = -hX, hX, step do
        for z = -hZ, hZ, step do
            local gy = groundH(x, z)
            local n1 = fnoise(x*0.02, z*0.02, 3, 0.5, 2, 1, W.SEED+141)
            local n2 = fnoise(x*0.045, z*0.045, 2, 0.5, 2, 1, W.SEED+211)

            -- Mosaico orgánico de Grass + LeafyGrass para evitar repetición visual.
            local mat = (n1 > 0.08 or n2 > 0.2) and Enum.Material.LeafyGrass or Enum.Material.Grass
            local hVar = 1.0 + math.max(0, n2) * 0.9
            Terrain:FillBlock(
                CFrame.new(x, gy-0.2, z),
                Vector3.new(step+1.2, hVar, step+1.2),
                mat
            )
            painted = painted + 1
        end
        task.wait()
    end

    -- Zonas de hierba alta Terrain (parches tipo pastizal).
    for i = 1, 460 do
        local gx = rng(-hX, hX)
        local gz = rng(-hZ, hZ)
        local gy = groundH(gx, gz)
        local patchW = rng(8, 18)
        local patchD = rng(8, 18)
        Terrain:FillBlock(
            CFrame.new(gx, gy-0.08, gz) * CFrame.Angles(0, rng(0, math.pi*2), 0),
            Vector3.new(patchW, rng(0.8, 1.6), patchD),
            Enum.Material.LeafyGrass
        )
    end

    print("✅ Hierba Terrain lista ("..painted.." celdas)")
end


-- ═══════════════════════════════════════════════════════════════
-- 4. FLORES DETALLADAS
-- ═══════════════════════════════════════════════════════════════
local FTYPES = {
    {W.C.F_RED,    W.C.F_YELLOW, 5, false},
    {W.C.F_PINK,   W.C.F_WHITE,  6, true},
    {W.C.F_YELLOW, W.C.F_ORANGE, 5, false},
    {W.C.F_BLUE,   W.C.F_WHITE,  6, true},
    {W.C.F_PURPLE, W.C.F_YELLOW, 5, false},
    {W.C.F_WHITE,  W.C.F_YELLOW, 6, true},
    {W.C.F_ORANGE, W.C.F_YELLOW, 5, false},
}

local function oneFlower(x, z, FF)
    local gy   = groundH(x, z)
    local ft   = FTYPES[rngi(1, #FTYPES)]
    local pCol, cCol, nPet, round = ft[1], ft[2], ft[3], ft[4]
    local sH   = rng(0.9, 1.8)
    local sW   = rng(0.11, 0.16)
    local tX   = rng(-12, 12)
    local tZ   = rng(-12, 12)

    -- Tallo
    mp({ n="FSt", sz=Vector3.new(sW,sH,sW),
         cf=CFrame.new(x, gy+sH*0.5, z)
           * CFrame.Angles(math.rad(tX), rng(0,math.pi*2), math.rad(tZ)),
         col=W.C.F_STEM, mat=Enum.Material.SmoothPlastic,
         cc=false, cs=false, par=FF })

    -- Hojitas
    if math.random() < 0.6 then
        for ls = -1, 1, 2 do
            mp({ n="FLf", sz=Vector3.new(rng(0.3,0.55),0.08,rng(0.18,0.32)),
                 cf=CFrame.new(x+ls*0.18, gy+sH*rng(0.3,0.6), z)
                   * CFrame.Angles(math.rad(rng(-20,20)), rng(0,math.pi*2), math.rad(ls*25)),
                 col=W.C.F_STEM, mat=Enum.Material.LeafyGrass,
                 cc=false, cs=false, par=FF })
        end
    end

    local topY  = gy + sH + 0.05
    local pSize = rng(0.34, 0.62)

    -- Pétalos
    for p = 1, nPet do
        local ang  = (p/nPet) * math.pi * 2
        local pDist = pSize * 0.72
        local pW   = pSize * (round and 1.1 or 0.75)
        local pH   = pSize * (round and 0.55 or 0.85)
        mp({ n="FP", sz=Vector3.new(pW, pH, pSize*0.25),
             cf=CFrame.new(x+math.cos(ang)*pDist, topY+pH*0.4, z+math.sin(ang)*pDist)
               * CFrame.Angles(math.rad(rng(-15,15)), ang, math.rad(-28)),
             col=pCol, mat=Enum.Material.SmoothPlastic,
             cc=false, cs=false, par=FF })
    end

    -- Centro
    mp({ n="FC", sz=Vector3.new(pSize*0.55, pSize*0.45, pSize*0.55),
         cf=CFrame.new(x, topY+pSize*0.28, z),
         col=cCol, mat=Enum.Material.Neon,
         cc=false, cs=false, par=FF })
end

local function buildFlowers(FF)
    local hX = W.SIZE_X*0.5 - 15
    local hZ = W.SIZE_Z*0.5 - 15
    local COUNT = 1800
    local done = 0

    for f = 1, COUNT do
        local fx = rng(-hX, hX)
        local fz = rng(-hZ, hZ)
        local fn2 = fnoise(fx*0.018, fz*0.018, 3, 0.5, 2, 1, W.SEED+55)
        if fn2 > -0.25 then
            local cN = rngi(1, 4)
            for c = 1, cN do
                oneFlower(fx + rng(-1.8,1.8), fz + rng(-1.8,1.8), FF)
                done = done + 1
            end
        end
        if f % 200 == 0 then
            task.wait()
            print(string.format("   Flores %d%%", math.floor(f/COUNT*100)))
        end
    end
    print("✅ Flores listas ("..done..")")
end

-- ═══════════════════════════════════════════════════════════════
-- 5. ROCAS  (moldeadas al suelo, con musgo)
-- ═══════════════════════════════════════════════════════════════
local function buildRocks(RF)
    local hX   = W.SIZE_X*0.5 - 45
    local hZ   = W.SIZE_Z*0.5 - 45
    local GROUPS = 280
    local count = 0

    for r = 1, GROUPS do
        local rx  = rng(-hX, hX)
        local rz  = rng(-hZ, hZ)
        local rn  = fnoise(rx*0.025, rz*0.025, 3, 0.5, 2.1, 1, W.SEED+301)
        local gr  = rng(5.5, 13.5)

        if rn >= -0.18 and not isOcc(rx, rz, gr+4) then
            markOcc(rx, rz, gr)
            local gy      = groundH(rx, rz)
            local hasMoss = math.random() < 0.62

            -- Base semienterrada para que no "floten".
            mp({ n="RBase", sz=Vector3.new(gr*2.3, rng(0.9,1.8), gr*2.1),
                 cf=CFrame.new(rx, gy+0.15, rz) * CFrame.Angles(0, rng(0, math.pi*2), 0),
                 col=lc(W.C.DIRT_D, W.C.R_DARK, rng(0.15,0.35)), mat=Enum.Material.Slate, par=RF })

            local cores = rngi(2, 4)
            for c = 1, cores do
                local ca = rng(0, math.pi*2)
                local cd = rng(0, gr*0.28)
                local cx = rx + math.cos(ca)*cd
                local cz = rz + math.sin(ca)*cd
                local ch = rng(2.5, 7.5)
                local cw = rng(2.0, 5.8)
                local cd2 = rng(1.8, 5.0)
                local cgy = groundH(cx, cz)

                mp({ n="RB", sz=Vector3.new(cw, ch, cd2),
                     cf=CFrame.new(cx, cgy+ch*0.45, cz)
                       * CFrame.Angles(math.rad(rng(-12,12)), math.rad(rng(0,360)), math.rad(rng(-10,10))),
                     col=lc(W.C.R_BASE, W.C.R_LIGHT, rng(0.12,0.88)), mat=Enum.Material.Rock, par=RF })

                if math.random() < 0.55 then
                    mw({ n="RCut", sz=Vector3.new(cw*rng(0.55,0.95), ch*rng(0.28,0.52), cd2*rng(0.55,0.95)),
                         cf=CFrame.new(cx+rng(-0.5,0.5), cgy+ch*0.74, cz+rng(-0.5,0.5))
                           * CFrame.Angles(math.rad(rng(-20,20)), math.rad(rng(0,360)), 0),
                         col=lc(W.C.R_LIGHT, W.C.R_BASE, 0.4), mat=Enum.Material.Slate, par=RF })
                end
            end

            -- Esquirlas y grava alrededor.
            for s2 = 1, rngi(10, 20) do
                local sa = rng(0, math.pi*2)
                local sd = rng(gr*0.45, gr*1.05)
                local sx = rx + math.cos(sa)*sd
                local sz = rz + math.sin(sa)*sd
                local ss = rng(0.35, 1.9)
                local sgy = groundH(sx, sz)
                mp({ n="RSm", sz=Vector3.new(ss, ss*rng(0.35,0.78), ss*rng(0.8,1.6)),
                     cf=CFrame.new(sx, sgy+ss*0.22, sz)
                       * CFrame.Angles(math.rad(rng(-22,22)), math.rad(rng(0,360)), math.rad(rng(-18,18))),
                     col=lc(W.C.R_BASE, W.C.R_LIGHT, math.random()), mat=Enum.Material.Rock, par=RF })
            end

            if hasMoss then
                for m = 1, rngi(2, 5) do
                    local ma = rng(0, math.pi*2)
                    local md = rng(0, gr*0.5)
                    local mx = rx + math.cos(ma)*md
                    local mz = rz + math.sin(ma)*md
                    local mgy = groundH(mx, mz)
                    mp({ n="RMoss", sz=Vector3.new(rng(1.3,3.6), rng(0.22,0.5), rng(1.2,3.2)),
                         cf=CFrame.new(mx, mgy+0.12, mz) * CFrame.Angles(0, rng(0, math.pi*2), 0),
                         col=lc(W.C.R_MOSS, W.C.G_WILD, rng(0.1,0.7)), mat=Enum.Material.Grass,
                         cc=false, cs=false, par=RF })
                end
            end

            count = count + 1
        end

        if r % 20 == 0 then
            task.wait()
            print(string.format("   Rocas %d%%", math.floor(r/GROUPS*100)))
        end
    end
    print("✅ Rocas realistas listas ("..count.." formaciones)")
end


-- ═══════════════════════════════════════════════════════════════
-- 6. MONTAÑAS  (estilo Pokémon DP)
-- Corregido: blockH declarado en scope correcto
-- ═══════════════════════════════════════════════════════════════
local function buildOnePeak(cx, cz, peakH, baseR, seed, MF)
    seed = seed or math.random()*200

    local function noiseR(angle, layer, baseRadius)
        local n = math.noise(
            math.cos(angle)*2.5 + cx*0.008 + seed*0.07 + layer*1.3,
            math.sin(angle)*2.5 + cz*0.008 + seed*0.07 + layer*0.9
        )
        return baseRadius * (1 + n*0.32)
    end

    local SEGS = 18
    local LYRS = math.floor(peakH / 10) + 4
    local FIXED_SEG_H = 11   -- altura fija de referencia para nieve (evita nil)

    for layer = 1, LYRS do
        local lt      = (layer-1) / (LYRS-1)
        local layerY  = W.BASE_Y + lt * peakH
        local layerR  = baseR * (1 - lt*0.86)

        -- Color por altura
        local layerCol
        if     lt > 0.82 then layerCol = lc(W.C.M_HIGH,  W.C.M_SNOW,  (lt-0.82)/0.18)
        elseif lt > 0.62 then layerCol = lc(W.C.M_MID,   W.C.M_HIGH,  (lt-0.62)/0.20)
        elseif lt > 0.38 then layerCol = lc(W.C.M_ROCK,  W.C.M_MID,   (lt-0.38)/0.24)
        else                   layerCol = lc(W.C.M_BASE,  W.C.M_ROCK,  lt/0.38)
        end

        local layerMat = lt > 0.78 and Enum.Material.Glacier
                      or (lt > 0.45 and Enum.Material.Slate or Enum.Material.Rock)

        -- Núcleo interior
        local coreR = math.max(layerR * 0.55, 2)
        mp({ n="MC", sz=Vector3.new(coreR*2, FIXED_SEG_H*(1-lt*0.6), coreR*1.85),
             cf=CFrame.new(cx, layerY+5, cz) * CFrame.Angles(0, math.rad(layer*22), 0),
             col=lc(layerCol, W.C.M_BASE, 0.25), mat=layerMat, par=MF })

        -- Anillo de bloques exterior
        for s = 1, SEGS do
            local ang  = (s/SEGS) * math.pi * 2
            local segR = noiseR(ang, layer, layerR)
            local segX = cx + math.cos(ang)*segR
            local segZ = cz + math.sin(ang)*segR
            local arcW = segR * (math.pi*2/SEGS) * 1.15
            -- segH declarado aquí, en scope del loop s — no puede ser nil
            local segH = rng(8, 15) * (1 - lt*0.55)
            local segD = rng(5, 10) * (1 - lt*0.3)

            mp({ n="MS", sz=Vector3.new(arcW, segH, segD),
                 cf=CFrame.new(segX, layerY+segH*0.5, segZ)
                   * CFrame.Angles(math.rad(rng(-2,2)*(1-lt)), ang, math.rad(rng(-2,2)*(1-lt))),
                 col=lc(layerCol, W.C.M_BASE, rng(0,0.2)), mat=layerMat, par=MF })

            -- Salientes de roca (cada 3 segmentos)
            if s % 3 == 0 and lt < 0.75 and segR > 10 then
                local jW   = arcW * rng(0.6, 1.0)
                local jH   = segH * rng(0.4, 0.75)
                local jD   = segD * rng(0.5, 0.9)
                local jDist = segR * 1.15
                mp({ n="MJ", sz=Vector3.new(jW, jH, jD),
                     cf=CFrame.new(cx+math.cos(ang)*jDist, layerY+segH*0.4+jH*0.3, cz+math.sin(ang)*jDist)
                       * CFrame.Angles(math.rad(rng(5,25)), ang, 0),
                     col=lc(W.C.M_ROCK, W.C.R_DARK, 0.3), mat=Enum.Material.Rock, par=MF })
                mw({ n="MWg", sz=Vector3.new(jW*0.7, jH*0.5, jD*0.8),
                     cf=CFrame.new(cx+math.cos(ang)*jDist*0.92, layerY+segH*0.1, cz+math.sin(ang)*jDist*0.92)
                       * CFrame.Angles(math.rad(-15), ang, 0),
                     col=W.C.M_BASE, mat=Enum.Material.Rock, par=MF })
            end
        end

        -- Nieve en capas altas
        -- Usamos FIXED_SEG_H como referencia de altura (siempre definida)
        if lt > 0.60 then
            local snowH     = 1.8
            local snowProb  = (lt-0.60)/0.40
            local snowSegs  = math.max(4, SEGS - math.floor(lt*8))

            for s = 1, snowSegs do
                if math.random() <= snowProb * 0.85 then
                    local sa  = (s/snowSegs) * math.pi * 2
                    local snR = noiseR(sa, layer, layerR) * rng(0.3, 0.85)
                    local snW = rng(3.5, math.max(3.6, layerR*0.65))
                    local snD = rng(2.5, math.max(2.6, layerR*0.52))
                    -- snY usa FIXED_SEG_H, siempre definida — corrige el error de nil
                    local snY = layerY + FIXED_SEG_H * (1 - lt*0.55) * 0.88

                    mp({ n="MSnow", sz=Vector3.new(snW, snowH, snD),
                         cf=CFrame.new(cx+math.cos(sa)*snR, snY+snowH*0.5, cz+math.sin(sa)*snR)
                           * CFrame.Angles(math.rad(rng(-10,10)), sa, 0),
                         col=(math.random()<0.6) and W.C.M_SNOW or W.C.M_SNOW2,
                         mat=Enum.Material.Glacier, cc=false, cs=false, par=MF })
                end
            end

            -- Casquete de nieve sólido
            if lt > 0.80 then
                local capR = layerR * rng(0.9, 1.1)
                mp({ n="MCap", sz=Vector3.new(capR*2, snowH*1.5, capR*1.9),
                     cf=CFrame.new(cx, layerY+snowH, cz) * CFrame.Angles(0, math.rad(layer*15), 0),
                     col=W.C.M_SNOW, mat=Enum.Material.Glacier,
                     cc=false, cs=false, par=MF })
            end
        end

        task.wait()
    end

    -- Pico final
    for pk = 1, 5 do
        local pkR = baseR * 0.055 * (6-pk)
        local pkH = peakH * 0.04
        mp({ n="MPk", sz=Vector3.new(pkR*2.2, pkH, pkR*2.0),
             cf=CFrame.new(cx+rng(-1,1), peakH+W.BASE_Y-pkH*pk*0.35, cz+rng(-1,1))
               * CFrame.Angles(math.rad(rng(-4,4)), math.rad(rng(0,360)), 0),
             col=pk <= 2 and W.C.M_SNOW or W.C.M_ICE,
             mat=Enum.Material.Glacier, cc=false, cs=false, par=MF })
    end

    -- Nubes
    if peakH > 60 then
        for cl = 1, rngi(3, 6) do
            local ca = rng(0, math.pi*2)
            local cr = rng(8, 28)
            local ch2 = peakH * rng(0.55, 0.75)
            local csz = rng(10, 24)
            mp({ n="MCloud", sz=Vector3.new(csz, csz*0.38, csz*0.78),
                 cf=CFrame.new(cx+math.cos(ca)*cr, W.BASE_Y+ch2, cz+math.sin(ca)*cr)
                   * CFrame.Angles(0, ca, 0),
                 col=Color3.fromRGB(245,248,255), mat=Enum.Material.SmoothPlastic,
                 tr=0.52, cc=false, cs=false, par=MF })
        end
    end
end

local function buildMountains(MF)
    local D = W.MTN_START

    local groups = {
        {x=0,      z=-(D+20),  h=rng(100,148), b=rng(38,55)},
        {x=-120,   z=-(D+60),  h=rng(80,125),  b=rng(30,48)},
        {x=120,    z=-(D+50),  h=rng(85,130),  b=rng(32,50)},
        {x=-280,   z=-(D+30),  h=rng(65,100),  b=rng(25,40)},
        {x=280,    z=-(D+40),  h=rng(70,110),  b=rng(28,44)},
        {x=0,      z= (D+20),  h=rng(100,142), b=rng(38,52)},
        {x=-130,   z= (D+55),  h=rng(75,118),  b=rng(28,46)},
        {x=130,    z= (D+48),  h=rng(78,122),  b=rng(30,48)},
        {x=-280,   z= (D+35),  h=rng(60,98),   b=rng(24,40)},
        {x=280,    z= (D+38),  h=rng(65,105),  b=rng(26,42)},
        {x=-(D+20),z=0,        h=rng(95,138),  b=rng(36,52)},
        {x=-(D+55),z=-130,     h=rng(72,115),  b=rng(28,45)},
        {x=-(D+50),z=130,      h=rng(78,120),  b=rng(30,47)},
        {x= (D+20),z=0,        h=rng(95,135),  b=rng(36,50)},
        {x= (D+55),z=-120,     h=rng(70,112),  b=rng(27,44)},
        {x= (D+48),z=120,      h=rng(75,118),  b=rng(29,46)},
        {x=-(D+30),z=-(D+30),  h=rng(85,128),  b=rng(32,50)},
        {x= (D+30),z=-(D+30),  h=rng(88,132),  b=rng(33,51)},
        {x=-(D+30),z= (D+30),  h=rng(82,125),  b=rng(30,48)},
        {x= (D+30),z= (D+30),  h=rng(86,130),  b=rng(32,50)},
    }

    local function transitionHill(hx, hz, hillH, hillR)
        local hLyrs = math.max(3, math.floor(hillH/12))
        for hl = 1, hLyrs do
            local hlt = (hl-1)/(hLyrs-1)
            local hlR = hillR*(1-hlt*0.78)
            local hlY = W.BASE_Y + hlt*hillH
            local hlH = hillH/hLyrs*1.2
            mp({ n="Hill", sz=Vector3.new(hlR*2, hlH, hlR*1.85),
                 cf=CFrame.new(hx, hlY+hlH*0.45, hz) * CFrame.Angles(0, math.rad(hlt*30), 0),
                 col=lc(W.C.M_BASE, W.C.M_ROCK, hlt),
                 mat=hlt > 0.5 and Enum.Material.Rock or Enum.Material.Grass,
                 par=MF })
        end
    end

    local total = #groups
    for i, g in ipairs(groups) do
        print(string.format("   Montañas: grupo %d/%d  h=%.0f", i, total, g.h))
        buildOnePeak(g.x, g.z, g.h, g.b, math.random()*200, MF)

        local extras = rngi(1, 2)
        for e = 1, extras do
            local ea = rng(0, math.pi*2)
            local ed = rng(g.b*1.1, g.b*2.0)
            buildOnePeak(g.x+math.cos(ea)*ed, g.z+math.sin(ea)*ed,
                         g.h*rng(0.38,0.75), g.b*rng(0.42,0.72),
                         math.random()*200, MF)
        end

        local toC = Vector3.new(-g.x, 0, -g.z)
        if toC.Magnitude > 0 then
            toC = toC.Unit
            for h = 1, rngi(3, 6) do
                local hDist = g.b*rng(1.5,3.5) + h*rng(15,28)
                transitionHill(g.x+toC.X*hDist, g.z+toC.Z*hDist,
                                g.h*rng(0.08,0.22), g.b*rng(0.5,1.0))
            end
        end


        -- Faldón de soporte para evitar montañas "viradas"
        for b = 1, 10 do
            local ba = (b/10) * math.pi * 2
            local br = g.b * rng(1.2, 1.65)
            local bx = g.x + math.cos(ba) * br
            local bz = g.z + math.sin(ba) * br
            local by = groundH(bx, bz)
            local bh = rng(7, 14)
            mp({ n="MSk", sz=Vector3.new(rng(16,26), bh, rng(10,18)),
                 cf=CFrame.new(bx, by+bh*0.45, bz) * CFrame.Angles(0, ba, 0),
                 col=lc(W.C.M_BASE, W.C.M_ROCK, rng(0.25,0.6)),
                 mat=Enum.Material.Rock, par=MF })
        end

        task.wait(0.1)
    end
    print("✅ Montañas listas ("..total.." grupos)")
end

-- ═══════════════════════════════════════════════════════════════
-- 7. ÁRBOLES
-- ═══════════════════════════════════════════════════════════════
local function buildTrees(TrF)
    local hX = W.SIZE_X*0.5-30; local hZ = W.SIZE_Z*0.5-30
    local COUNT = 320; local done = 0; local tries = 0

    while done < COUNT and tries < COUNT*7 do
        tries = tries + 1
        local tx = rng(-hX, hX); local tz = rng(-hZ, hZ)
        local fn3 = fnoise(tx*0.022, tz*0.022, 3, 0.5, 2, 1, W.SEED+99)

        if fn3 >= 0.03 and not isOcc(tx, tz, 7) then
            markOcc(tx, tz, 6)
            local gy = groundH(tx, tz)
            local tt = rngi(1, 3)

            if tt == 1 then
                local trH = rng(4.5, 9); local trW = rng(0.8, 1.4); local cpR = rng(4, 7)
                mp({ n="TrRt", sz=Vector3.new(trW*1.7, rng(0.35,0.7), trW*1.7),
                     pos=Vector3.new(tx, gy+0.15, tz), col=W.C.DIRT_D,
                     mat=Enum.Material.Ground, par=TrF })
                mp({ n="Trk", sz=Vector3.new(trW,trH,trW),
                     cf=CFrame.new(tx,gy+trH*0.5+0.15,tz)*CFrame.Angles(0,rng(0,math.pi*2),0),
                     col=lc(W.C.T_TRUNK,W.C.T_BARK,rng(0,0.6)), mat=Enum.Material.Wood, par=TrF })
                mp({ n="Can", sz=Vector3.new(cpR*2,cpR*1.55,cpR*2),
                     pos=Vector3.new(tx,gy+trH+cpR*0.65,tz),
                     col=lc(W.C.T_LEAF1,W.C.T_LEAF2,rng(0,1)), mat=Enum.Material.LeafyGrass, cc=false, par=TrF })
                for lf = 1, 4 do
                    local la = (lf/4)*math.pi*2+rng(0,0.4); local ld = cpR*0.55; local ls = cpR*rng(0.55,0.88)
                    mp({ n="Lf", sz=Vector3.new(ls*1.55,ls*0.9,ls*1.55),
                         pos=Vector3.new(tx+math.cos(la)*ld, gy+trH+cpR*rng(0.35,0.65), tz+math.sin(la)*ld),
                         col=lc(W.C.T_LEAF1,W.C.T_LEAF3,rng(0,1)), mat=Enum.Material.LeafyGrass,
                         cc=false, cs=false, par=TrF })
                end

            elseif tt == 2 then
                local trH = rng(7,14); local cpR = rng(3.5,5.5); local cones = rngi(3,5)
                mp({ n="PRt", sz=Vector3.new(1.45, rng(0.35,0.65), 1.45),
                     pos=Vector3.new(tx, gy+0.15, tz),
                     col=W.C.DIRT_D, mat=Enum.Material.Ground, par=TrF })
                mp({ n="PTrk", sz=Vector3.new(0.75,trH,0.75),
                     pos=Vector3.new(tx,gy+trH*0.5+0.15,tz),
                     col=W.C.T_TRUNK, mat=Enum.Material.Wood, par=TrF })
                for c = 1, cones do
                    local ct = (c-1)/(cones-1); local cR = cpR*(1-ct*0.65)
                    local cH = rng(3.5,6); local cY = gy+trH*0.28+ct*trH*0.68
                    mp({ n="PCn", sz=Vector3.new(cR*2,cH,cR*2),
                         pos=Vector3.new(tx,cY+cH*0.5,tz),
                         col=lc(W.C.T_PINE,W.C.T_PINE2,ct), mat=Enum.Material.LeafyGrass, cc=false, par=TrF })
                end

            else
                local trH = rng(3.5, 7)
                mp({ n="FRt", sz=Vector3.new(1.7, rng(0.35,0.75), 1.7),
                     pos=Vector3.new(tx, gy+0.15, tz),
                     col=W.C.DIRT_D, mat=Enum.Material.Ground, par=TrF })
                mp({ n="FTrk", sz=Vector3.new(1.0,trH,1.0),
                     pos=Vector3.new(tx,gy+trH*0.5+0.15,tz),
                     col=W.C.T_BARK, mat=Enum.Material.Wood, par=TrF })
                for hl = 1, 3 do
                    local lR = rng(3,5.5)*(1-hl*0.18)
                    mp({ n="FLf", sz=Vector3.new(lR*2,1.8,lR*2),
                         pos=Vector3.new(tx, gy+trH*0.6+hl*2, tz),
                         col=lc(W.C.T_LEAF1,W.C.T_LEAF3,hl/3), mat=Enum.Material.LeafyGrass,
                         cc=false, par=TrF })
                end
            end

            done = done + 1
        end

        if tries % 25 == 0 then task.wait()
            print(string.format("   Árboles %d/%d", done, COUNT))
        end
    end
    print("✅ Árboles listos ("..done..")")
end

-- ═══════════════════════════════════════════════════════════════
-- 8. AGUA
-- ═══════════════════════════════════════════════════════════════
local function buildWater(WF)
    local lx = rng(-80,80); local lz = rng(-80,80)
    local lW = rng(40,65);  local lD = rng(35,55)

    mp({ n="LkFl", sz=Vector3.new(lW+6,2,lD+6),
         pos=Vector3.new(lx, W.BASE_Y-2.8, lz),
         col=Color3.fromRGB(45,75,35), mat=Enum.Material.Mud, par=WF })

    local surf = mp({ n="LkSr", sz=Vector3.new(lW,0.5,lD),
         pos=Vector3.new(lx, W.BASE_Y-0.45, lz),
         col=W.C.W_DEEP, mat=Enum.Material.Glass, tr=0.28, cc=false, par=WF })

    mp({ n="LkRf", sz=Vector3.new(lW-3,0.1,lD-3),
         pos=Vector3.new(lx, W.BASE_Y-0.08, lz),
         col=W.C.W_SHALLOW, mat=Enum.Material.Neon, tr=0.65, cc=false, cs=false, par=WF })

    for s = 1, 10 do
        local sa = (s/10)*math.pi*2
        mp({ n="Sh", sz=Vector3.new(rng(5,10),0.7,rng(4,8)),
             cf=CFrame.new(lx+math.cos(sa)*lW*0.56, W.BASE_Y+0.1, lz+math.sin(sa)*lD*0.56)
               * CFrame.Angles(0,sa,0),
             col=lc(W.C.SAND,W.C.SAND_D,rng(0,0.5)), mat=Enum.Material.Sand, par=WF })
    end

    local wL = Instance.new("PointLight")
    wL.Brightness = 1.2; wL.Range = math.max(lW,lD)*1.3
    wL.Color = Color3.fromRGB(70,145,255); wL.Parent = surf

    local rSegs = 12; local rDir = math.random()<0.5 and 1 or -1
    for rs = 1, rSegs do
        local rt  = (rs-1)/(rSegs-1)
        local rpx = lx + rDir*(lW*0.48 + rs*(W.SIZE_X*0.5-50)/rSegs)
        local rpz = lz + math.sin(rt*math.pi*2.5)*22
        mp({ n="Rv", sz=Vector3.new(W.SIZE_X/(rSegs*2)+2, 0.4, 9),
             pos=Vector3.new(rpx, W.BASE_Y-0.35-rt*2, rpz),
             col=W.C.W_MID, mat=Enum.Material.Glass, tr=0.32, cc=false, par=WF })
    end

    task.spawn(function()
        while surf.Parent do
            local t = tick()
            surf.Transparency = 0.28 + math.sin(t*0.7)*0.04
            surf.Color = lc(W.C.W_DEEP, W.C.W_MID, (math.sin(t*0.4)+1)*0.5*0.28)
            task.wait(0.1)
        end
    end)
    print("✅ Agua lista")
end

-- ═══════════════════════════════════════════════════════════════
-- 9. CAMINO
-- ═══════════════════════════════════════════════════════════════
local function buildPath(PF)
    local segs = 36; local hZ2 = W.SIZE_Z*0.5
    for s = 1, segs do
        local t  = (s-1)/(segs-1)
        local t2 = math.min(1, s/(segs-1))
        local pz = -hZ2 + t*W.SIZE_Z
        local px = math.sin(t*math.pi*2.2)*18
        local nz = -hZ2 + t2*W.SIZE_Z
        local nx = math.sin(t2*math.pi*2.2)*18
        local dir = Vector3.new(nx-px, 0, nz-pz)
        local segLen = math.max(9.5, dir.Magnitude + 2.6)
        local py = groundH(px, pz) + 0.15
        local pcf = CFrame.lookAt(Vector3.new(px, py, pz), Vector3.new(px, py, pz)+dir)
        mp({ n="Pt", sz=Vector3.new(7.5, 0.55, segLen),
             cf=pcf,
             col=lc(W.C.DIRT, W.C.DIRT_L, math.noise(t*5)*0.5+0.5),
             mat=Enum.Material.Ground, par=PF })
        for side = -1, 1, 2 do
            mp({ n="PE", sz=Vector3.new(0.6, 0.65, segLen),
                 cf=pcf * CFrame.new(side*3.95, 0.3, 0),
                 col=W.C.G_BASE, mat=Enum.Material.Grass, par=PF })
        end
    end
    print("✅ Camino listo")
end

-- ═══════════════════════════════════════════════════════════════
-- 10. SPAWN
-- ═══════════════════════════════════════════════════════════════
local function setupSpawn()
    local sp = Workspace:FindFirstChild("SpawnLocation")
    if not sp then sp = Instance.new("SpawnLocation"); sp.Parent = Workspace end
    sp.Position   = Vector3.new(0, W.BASE_Y+4, 0)
    sp.Size        = Vector3.new(8, 1, 8)
    sp.BrickColor  = BrickColor.new("Bright red")
    sp.Material    = Enum.Material.SmoothPlastic
    sp.Anchored    = true
    sp.Neutral     = true
    print("✅ Spawn listo")
end

-- ═══════════════════════════════════════════════════════════════
-- MAIN
-- ═══════════════════════════════════════════════════════════════
local function buildWorld()
    print("════════════════════════════════════════════════")
    print("🌿 POKÉMON WORLD v2.0 — Generando mundo…")
    print("════════════════════════════════════════════════")
    local t0 = tick()

    local old = Workspace:FindFirstChild("PokemonWorld")
    if old then old:Destroy() end
    occupied = {}

    FW = mkFolder("PokemonWorld")
    local TF  = mkFolder("Terrain",   FW)
    local GF  = mkFolder("Grass",     FW)
    local FlF = mkFolder("Flowers",   FW)
    local RF  = mkFolder("Rocks",     FW)
    local MF  = mkFolder("Mountains", FW)
    local TrF = mkFolder("Trees",     FW)
    local WF2 = mkFolder("Water",     FW)
    local PF  = mkFolder("Paths",     FW)

    print("🌅 [1/9] Atmósfera…")  ; setupAtmosphere()
    print("🌱 [2/9] Terreno…")    ; buildTerrain(TF)
    print("🌿 [3/9] Hierba…")     ; buildGrass(GF)
    print("🌸 [4/9] Flores…")     ; buildFlowers(FlF)
    print("🪨 [5/9] Rocas…")      ; buildRocks(RF)
    print("⛰️  [6/9] Montañas…")   ; buildMountains(MF)
    print("🌳 [7/9] Árboles…")    ; buildTrees(TrF)
    print("💧 [8/9] Agua…")       ; buildWater(WF2)
    print("🛤️  [9/9] Camino…")     ; buildPath(PF) ; setupSpawn()

    print("════════════════════════════════════════════════")
    print(string.format("✅ Mundo listo en %.1f s  |  %dx%d studs",
          tick()-t0, W.SIZE_X, W.SIZE_Z))
    print("════════════════════════════════════════════════")
end

buildWorld()
