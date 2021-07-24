---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Bergi.
--- DateTime: 13.02.2021 22:18
---
function StartAndReleaseSpin(data, duration)
    local hero = data.UnitHero
    local a = 0
    local sec = 0
    local freeSpin=false
    UnitRemoveAbility(hero,FourCC("Beng"))
    if not duration then
        duration = 0
    else
        freeSpin=true
    end
    if data.SpinRegeneratingRate == 0 then
        data.SpinRegeneratingRate = 1
        TimerStart(CreateTimer(), 1, true, function()
            if data.SpinCharges < data.SpinChargesMAX then
                data.SpinCharges = data.SpinCharges + data.SpinRegeneratingRate
                BlzFrameSetText(data.SpinChargesFH, data.SpinCharges)
            end
        end)
    end

    if data.SpinCharges > 0 or duration > 0 then
        TimerStart(CreateTimer(), TIMER_PERIOD, true, function()
            local x, y = GetUnitXY(hero)
            local eff = nil
            duration=duration-TIMER_PERIOD
            BlzSetUnitFacingEx(hero, a)
            SetUnitAnimationByIndex(hero,data.IndexAnimationSpin)
            a = a - 20
            sec = sec + TIMER_PERIOD
            if sec >= 0.1 and data.SpinCharges > 0 then
                eff = AddSpecialEffect("Hive\\Culling Slash\\Culling Slash\\Culling Slash", x, y)
                if duration <= 0 then
                    data.SpinCharges = data.SpinCharges - 1
                end
                data.SpinReflect = true
                BlzFrameSetText(data.SpinChargesFH, data.SpinCharges)
                DestroyEffect(eff)
                BlzSetSpecialEffectScale(eff, data.ChargedSpinArea / 300)
                sec = 0
                local state = ""
                if data.ChargedSpinArea > 200 then
                    state = "blackHole"
                end
                local damage = data.SpinBaseDamage
                if data.SpinHasAddDamage then
                    local talon = GlobalTalons[data.pid]["HeroBlademaster"][5]
                    local k = talon.DS[talon.level]
                    damage = damage * k
                end
                if UnitDamageArea(hero, damage, x, y, data.ChargedSpinArea, state) then
                    normal_sound("Sound\\Units\\Combat\\MetalMediumBashStone" .. GetRandomInt(1, 3), GetUnitXY(data.UnitHero))
                end
            end

            local t = CreateTimer()
            local sec2 = 0
            TimerStart(t, TIMER_PERIOD64, true, function()
                sec2 = sec2 + TIMER_PERIOD
                if sec2 >= 1 then
                    PauseTimer(t)
                    DestroyTimer(t)
                end
                BlzSetSpecialEffectPosition(eff, GetUnitX(hero), GetUnitY(hero), BlzGetUnitZ(hero) + 30)
            end)
            if ((not data.isSpined or data.SpinCharges <= 0 or not UnitAlive(hero)) and not freeSpin) or (freeSpin and duration <= 0) then
                --print("stopspin")
                data.SpinReflect = false
                data.isSpined = false
                data.PressSpin = false
                DestroyTimer(GetExpiredTimer())
            end
        end)
    end
end