do
    local InitGlobalsOrigin = InitGlobals
    function InitGlobals()
        InitGlobalsOrigin()
        TimerStart(CreateTimer(), 0.1, false, function()
            InitDamage()
            DestroyTimer(GetExpiredTimer())
        end)
    end
end

function OnPostDamage()
    local damage = GetEventDamage() -- число урона
    local damageType = BlzGetEventDamageType()
    if damage < 1 then
        return
    end
    local target = GetTriggerUnit() -- тот кто получил урон
    local caster = GetEventDamageSource() -- тот кто нанёс урон

    --print(GetUnitName(target))


    if GetUnitTypeId(caster) == HeroID and caster ~= target then
        local data = HERO[GetPlayerId(GetOwningPlayer(caster))]
        local x, y = GetUnitXY(caster)
        local xe, ye = GetUnitXY(target)
        -- функция принадлежности точки сектора
        -- x1, x2 - координаты проверяемой точки
        -- x2, y2 - координаты вершины сектора
        -- orientation - ориентация сектора в мировых координатах
        -- width - угловой размер сектора в градусах
        -- radius - окружности которой принадлежит сектор

        if IsPointInSector(x, y, xe, ye, GetUnitFacing(target) - 180, 90, 200) then
            BlzSetEventDamage(damage * data.BackDamage)
            FlyTextTagShieldXY(x, y, L("Удар в спину", "Back stab"), GetOwningPlayer(caster))

            local eff = AddSpecialEffect("Hive\\Coup de Grace\\noSlash\\Coup de Grace", xe, ye)
            BlzSetSpecialEffectYaw(eff, math.rad(GetUnitFacing(target) ))
            --BlzSetSpecialEffectPitch(eff, math.rad(-90))
        end
        if data.UrsaStackFH then
            UnitAddUrsaStack(target, 1)
            local stack = UnitGetUrsaStack(target)
            BlzSetEventDamage(GetEventDamage() + (stack * data.UrsaBonus))
        end

        if data.CriticalStrikeCDFH then
            if data.CriticalStrikeCurrentCD <= 0 then
                local talon = GlobalTalons[data.pid]["HeroBlademaster"][2]
                local cd = talon.DS[talon.level]
                data.CriticalStrikeCurrentCD = cd
                StartFrameCD(cd, data.CriticalStrikeCDFH)

                local talonM = GlobalTalons[data.pid]["HeroBlademaster"][3]
                local ks = 1.5
                if data.HasMultipleCritical then
                    if talonM.level > 0 then
                        ks = talonM.DS[talonM.level]
                    end
                end
                BlzSetEventDamage(GetEventDamage() * ks)

                TimerStart(CreateTimer(), cd, false, function()
                    data.CriticalStrikeCurrentCD = 0
                    DestroyTimer(GetExpiredTimer())
                end)
            end

        end
    end

    if GetUnitTypeId(target) ~= HeroID then
        --print("кто-то другой получил урон")
        local data = HERO[GetPlayerId(GetOwningPlayer(caster))]
        if data then
            if not IsUnitHasShield(target) then
                local addTime = 0
                if not data.StaggerTimeFromTalon then
                    data.StaggerTimeFromTalon = 0
                end
                if data.StaggerTimeFromTalon then
                    addTime = data.StaggerTimeFromTalon
                end

                local _, status = IsUnitStunned(target)
                if status == "stagger" then
                    --print("юнит уже оглушен")
                end
                if status == "frise" then
                    -- print("юнит получает урон будучи замороженным")
                    if GetUnitTypeId(caster) == FourCC("nwwd") then
                        BlzSetEventDamage(GetEventDamage() * 2)
                    end
                end

                StunUnit(target, 0.4 + addTime, "stagger")
            else
                if data.ShieldBreakerIsLearn then
                    damage = damage + 50
                end
                SetUnitState(target, UNIT_STATE_MANA, GetUnitState(target, UNIT_STATE_MANA) - damage)
                BlzSetEventDamage(0)
                if IsUnitHasShield(target) and GetUnitState(target, UNIT_STATE_MANA) < 1 then
                    local x, y = GetUnitXY(target)
                    FlyTextTagShieldXY(x, y, L("Броня сломана", "Armor is broken"), GetOwningPlayer(caster), "blue")
                    ShieldSystem[GetHandleId(target)].IsActive = false
                    if data.ChainDestroyShield then
                        DestroyEffect(AddSpecialEffect("SystemGeneric\\Lightning Shock", x, y))
                        DestroyShieldArea(data, 450, x, y)
                    end
                else
                    local x, y = GetUnitXY(target)
                    FlyTextTagShieldXY(x, y, L("Блок: ", "Blocked: ") .. R2I(damage), GetOwningPlayer(caster))
                end
            end
        end
    else
        --print("наш герой получил урон")
        local data = HERO[GetPlayerId(GetOwningPlayer(target))]
        data.StatDamageGained = data.StatDamageGained + GetEventDamage()
        local x, y = GetUnitXY(caster)
        local xe, ye = GetUnitXY(target)
        -- функция принадлежности точки сектора
        -- x1, x2 - координаты проверяемой точки
        -- x2, y2 - координаты вершины сектора
        -- orientation - ориентация сектора в мировых координатах
        -- width - угловой размер сектора в градусах
        -- radius - окружности которой принадлежит сектор
        if data.AvatarSkin then
            local maxHP = BlzGetUnitMaxHP(target)
            local amount = (maxHP * data.AvatarSkin) / 100
            if GetEventDamage() > amount then
                --print("урон сокращен до",amount)
                BlzSetEventDamage(amount)
            end
        end

        if data.BloodSlow then
            local _, _, _, all = UnitDamageArea(target, 50, xe, ye, 250)
            for i = 1, #all do
                SlowUnit(all[i], data.BloodSlow)
            end
        end
        if data.EvilSoulCDFH then
            if data.EvilSoulCurrentCD <= 0 then
                local cd = data.EvilSoulCD
                data.EvilSoulCurrentCD = cd
                StartFrameCD(cd, data.EvilSoulCDFH)
                SetUnitInvulnerable(data.UnitHero, true)
                local effInv = AddSpecialEffectTarget("Abilities\\Spells\\Orc\\Voodoo\\VoodooAura.mdl", data.UnitHero, "origin")
                TimerStart(CreateTimer(), 0.5, false, function()
                    SetUnitInvulnerable(data.UnitHero, false)
                    DestroyEffect(effInv)
                    DestroyTimer(GetExpiredTimer())
                end)
                TimerStart(CreateTimer(), cd, false, function()
                    data.EvilSoulCurrentCD = 0
                    DestroyTimer(GetExpiredTimer())
                    DestroyTimer(GetExpiredTimer())
                end)
            end
        end

        if data.CurrentWeaponType == "shield" and data.PressSpin then
            if IsPointInSector(x, y, xe, ye, GetUnitFacing(target), 90, 200) then
                if not data.ReturnShieldDamage then
                    data.ReturnShieldDamage = 0
                end
                UnitDamageTarget(target, caster, GetEventDamage() * data.ReturnShieldDamage, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_NORMAL, WEAPON_TYPE_WHOKNOWS) --torn, отраженный урон
                data.StatBlockGained = data.StatBlockGained + GetEventDamage()
                BlzSetEventDamage(0)
                local eff = AddSpecialEffect("SystemGeneric\\DefendCaster", GetUnitXY(target))
                local AngleSource = AngleBetweenUnits(caster, target)
                BlzSetSpecialEffectYaw(eff, math.rad(AngleSource - 180))
                DestroyEffect(eff)
                UnitAddForceSimple(data.UnitHero, AngleSource, 10, 50)
                FlyTextTagShieldXY(xe, ye, L("Удар в щит", "In shield"), GetOwningPlayer(target))

                if not IsUnitTrap(caster) and data.ShieldHealCDFH then
                    if data.ShieldHealCurrentCD <= 0 then
                        --AddGold(data, -10)
                        local cd = data.ShieldHealCD
                        data.ShieldHealCurrentCD = cd
                        StartFrameCD(cd, data.ShieldHealCDFH)
                        HealUnit(target, data.ShieldHealRate)
                        TimerStart(CreateTimer(), cd, false, function()
                            data.ShieldHealCurrentCD = 0
                            DestroyTimer(GetExpiredTimer())
                        end)
                    end
                end


            end
        end

        if data.HealDash and data.HealDashCurrentCD <= 0 then
            --лечение рывком
            data.Time2HealDash = damage
            TimerStart(CreateTimer(), 0.5, false, function()
                data.Time2HealDash = 0
                DestroyTimer(GetExpiredTimer())
            end)
        end
        if data.LeakyBag then
            AddGold(data, -damage * data.LeakyBag)
            BlzSetEventDamage(damage * (1 - data.LeakyBag))
        end

        if data.FlipTheCoinCDFH then
            if data.FlipTheCoinCurrentCD <= 0 and data.gold > 10 then
                AddGold(data, -10)
                local cd = data.FlipTheCoinCD
                data.FlipTheCoinCurrentCD = cd
                StartFrameCD(cd, data.FlipTheCoinCDFH)

                if GetRandomInt(1, 2) == 1 then
                    data.StatBlockGained = data.StatBlockGained + GetEventDamage()
                    BlzSetEventDamage(0)
                    FlyTextTagGoldBounty(target, "Удача", GetOwningPlayer(target))
                else

                end
                TimerStart(CreateTimer(), cd, false, function()
                    data.FlipTheCoinCurrentCD = 0
                    DestroyTimer(GetExpiredTimer())
                end)
            end
        end

        if damage >= GetUnitState(target, UNIT_STATE_LIFE) then
            -- смертельный урон от тралла
            --print("получен смертельный урон")

            if data.InvulPreDeathCurrentCD <= 0 and data.InvulPreDeathCDFH then
                --print("получен смертельный урон")
                FlyTextTagHealXY(GetUnitX(target), GetUnitY(target), L("Предвидение смерти", "Foresight of Death"), GetOwningPlayer(target))
                --CreateInfoBoxForAllPlayerTimed(data, L("Я не дам тебе умереть", "I won't let you die"), 3)
                data.StatBlockGained = data.StatBlockGained + GetEventDamage()
                BlzSetEventDamage(0)
                SetUnitInvulnerable(target, true)
                TimerStart(CreateTimer(), 2, false, function()
                    SetUnitInvulnerable(target, false)
                    DestroyTimer(GetExpiredTimer())
                end)
                local talon = GlobalTalons[data.pid]["Trall"][8]
                local cd = talon.DS[talon.level]
                data.InvulPreDeathCurrentCD = cd
                StartFrameCD(cd, data.InvulPreDeathCDFH)
                TimerStart(CreateTimer(), cd, false, function()
                    data.InvulPreDeathCurrentCD = 0
                    DestroyTimer(GetExpiredTimer())
                end)
            end
        end
        if data.WindWalkCDFH then
            -- есть фрейм призрачного шага
            --print("талант изучен")
            if data.WindWalkCurrentCD <= 0 and GetUnitLifePercent(target) <= 30 then
                --print("условия выполнены")
                local talon = GlobalTalons[data.pid]["HeroBlademaster"][1]
                local cd = talon.DS[talon.level]
                data.WindWalkCurrentCD = cd
                StartFrameCD(cd, data.WindWalkCDFH)
                --print("в инвиз")
                SetUnitInvulnerable(target, true)
                TimerStart(CreateTimer(), 0.1, false, function()
                    SetUnitInvulnerable(target, false)
                    DestroyTimer(GetExpiredTimer())
                end)
                UnitAddItemById(target, FourCC("I001"))
                TimerStart(CreateTimer(), cd, false, function()
                    data.WindWalkCurrentCD = 0
                    DestroyTimer(GetExpiredTimer())
                end)
            end
        end
        if data.ParryPerAttack and false then
            --print("Парировал")
            local eff = AddSpecialEffect("SystemGeneric\\DefendCaster", GetUnitXY(target))
            local AngleSource = AngleBetweenUnits(caster, target)
            BlzSetSpecialEffectYaw(eff, math.rad(AngleSource - 180))
            DestroyEffect(eff)
            data.StatBlockGained = data.StatBlockGained + GetEventDamage()
            BlzSetEventDamage(0)
        end
        if GetEventDamage() > 5 and data.RevengeLightingDamage and not IsUnitTrap(caster) then
            local eff = AddSpecialEffect("Doodads\\Cinematic\\Lightningbolt\\Lightningbolt", GetUnitXY(caster))
            -- print("где эффект")
            TimerStart(CreateTimer(), 0.5, false, function()
                DestroyEffect(eff)
                DestroyTimer(GetExpiredTimer())
            end)
            UnitDamageTarget(target, caster, data.RevengeLightingDamage, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_NORMAL, WEAPON_TYPE_WHOKNOWS)
        end

    end

    if GetUnitTypeId(target) ~= HeroID and GetUnitTypeId(caster) == HeroID then
        --Функция должна быть в самом низу
        AddDamage2Show(target, GetEventDamage())
        local data = GetUnitData(caster)
        data.StatDamageDealing = data.StatDamageDealing + GetEventDamage()
        local showData = ShowDamageTable[GetHandleId(target)]
        local matchShow = showData.damage
        if matchShow >= 1 then
            if not showData.tag then
                showData.tag = FlyTextTagCriticalStrike(target, R2I(matchShow), GetOwningPlayer(caster), true)
            else

                SetTextTagText(showData.tag, R2I(matchShow), 0.024 + (showData.k))
                SetTextTagVelocity(showData.tag, 0, 0.01)
                SetTextTagLifespan(showData.tag, 99)

            end
        end
    end


end

function IsUnitTrap(unit)
    return GetUnitAbilityLevel(unit, FourCC("A005")) > 0
end

ShowDamageTable = {}
function AddDamage2Show(hero, damage)
    local sec2Reset = 1
    local period = TIMER_PERIOD
    if not ShowDamageTable[GetHandleId(hero)] then
        --	print("получил урон первый раз")
        ShowDamageTable[GetHandleId(hero)] = {
            damage = 0,
            sec = 0,
            tag = nil,
            k = 0
        }
        local data = ShowDamageTable[GetHandleId(hero)]
        data.damage = damage
        TimerStart(CreateTimer(), period, true, function()
            if not UnitAlive(hero) then
                DestroyTimer(GetExpiredTimer())
                --SetTextTagLifespan(data.tag, 2)
                --DestroyTextTag(data.tag)
                --print("таймер уничтожен")
                TimerStart(CreateTimer(), 1, false, function()
                    DestroyTextTag(data.tag)
                    data.tag = nil
                    DestroyTimer(GetExpiredTimer())
                end)
            end

            SetTextTagPos(data.tag, GetUnitX(hero), GetUnitY(hero), 0)
            data.sec = data.sec + period
            if data.sec > sec2Reset then
                data.sec = 0
                data.damage = 0
                SetTextTagLifespan(data.tag, 2)
                --DestroyTextTag(data.tag)
                data.k = 0
                data.tag = nil
                --print("сброс показа урона")
            end
        end)
    else
        local data = ShowDamageTable[GetHandleId(hero)]
        data.sec = 0
        data.damage = data.damage + damage
        data.k = data.k + 0.002
        if data.k >= 0.04 then
            data.k = 0.04 -- достигнут предел размера урона
        end
        --print("Добавление урона"..damage.." и всего получилось "..data.damage)
    end

end

function InitDamage()
    local DamageTrigger = CreateTrigger()
    for i = 0, bj_MAX_PLAYER_SLOTS - 1 do
        --TriggerRegisterPlayerUnitEvent(DamageTrigger, Player(i), EVENT_PLAYER_UNIT_DAMAGING) -- До вычета брони
        TriggerRegisterPlayerUnitEvent(DamageTrigger, Player(i), EVENT_PLAYER_UNIT_DAMAGED) -- После вычета брони
    end
    TriggerAddAction(DamageTrigger, OnPostDamage)
end

GlobalRect = Rect(0, 0, 0, 0)
function PointContentDestructable (x, y, range, iskill, damage, hero)
    local content = false
    local contentedDest = nil
    local unitZ = GetUnitZ(hero)
    if range == nil then
        range = 80
    end
    if iskill == nil then
        iskill = false
    end
    --print(GetUnitName(hero))
    SetRect(GlobalRect, x - range, y - range, x + range, y + range)
    EnumDestructablesInRect(GlobalRect, nil, function()
        local d = GetEnumDestructable()
        if GetDestructableLife(d) > 0 then
            --and unitZ<=GetTerrainZ(x,y)+50
            content = true
            contentedDest = d
            --print("эх")
            if iskill then
                if not IsDestructableInvulnerable(d) then
                    SetDestructableLife(d, GetDestructableLife(d) - damage)
                    --print("урон по декору")
                    if GetDestructableLife(d) < 1 or GetDestructableLife(d) <= 0 then
                        --print("смерть декора")
                        local dx, dy = GetDestructableX(d), GetDestructableY(d)
                        if hero then
                            if GetRandomInt(1, 2) == 1 then
                                if GetDestructableTypeId(d) == FourCC("B004") then
                                    --print("умер ящик, создаём мимика")
                                    local new = CreateUnit(Player(10), FourCC("n000"), GetDestructableX(d), GetDestructableY(d), 0)
                                    IssueTargetOrder(new, "attack", hero)
                                end
                            else
                                --print("даём золото за сундук")
                                if GetDestructableTypeId(d) == FourCC("B008") or GetDestructableTypeId(d) == FourCC("B004") then
                                    UnitAddGold(hero, GetRandomInt(2, 5))
                                    DestroyEffect(AddSpecialEffect("SystemGeneric\\PileofGold.mdl", dx, dy))
                                end
                            end
                        end
                        if GetDestructableTypeId(d) == FourCC("B008") then
                            --print("умерла ваза горшок в событии проверки")
                            normal_sound("Abilities\\Spells\\Other\\Transmute\\AlchemistTransmuteDeath1", dx, dy, 60)
                            DestroyEffect(AddSpecialEffect("Objects\\Spawnmodels\\Undead\\ImpaleTargetDust\\ImpaleTargetDust.mdl", dx, dy))
                            TimerStart(CreateTimer(), 0.6, false, function()
                                RemoveDestructable(d)
                                DestroyTimer(GetExpiredTimer())
                            end)
                            if IsUnitType(hero, UNIT_TYPE_HERO) then
                                local data = HERO[GetPlayerId(GetOwningPlayer(hero))]
                                --print(data.VaseGainGold)
                                if data.VaseGainGold then
                                    HealUnit(hero, data.VaseGainGold)
                                end
                            end
                        end
                        if GetDestructableTypeId(d) == FourCC("BTsc") then
                            local eff = AddSpecialEffect("SystemGeneric\\ThunderclapCasterClassic", dx, dy)
                            DestroyEffect(eff)

                            PlayerSeeNoiseInRangeTimed(0.8,dx,dy)
                            --print("смерть балки от рук"..GetUnitName(hero))

                            if hero then
                                if IsUnitType(hero, UNIT_TYPE_HERO) then
                                    local data = GetUnitData(hero)
                                    if GetRandomInt(1, 6) == 1 then
                                        local rm = {
                                            L("Упс", "Oops"),
                                            L("Ой", "Oh"),
                                            L("Оно само", "It is itself"),
                                            L("Я не хотел", "I didn't want"),
                                            L("Цепная реакция", "Chain reaction"),
                                            L("Я не думал что так получится", "I didn't think that would happen"),
                                            L("Никого не придавило?", "No one got pinned down?"),
                                            L("Все живы?", "Is everyone alive?"),
                                            L("Я случайно", ""),
                                            L("Ай, мизинцем ударился", ""),
                                        }
                                        CreateInfoBoxForAllPlayerTimed(data, rm[GetRandomInt(1, #rm)], 3)
                                    end
                                end
                                TimerStart(CreateTimer(), 0.6, false, function()
                                    UnitDamageArea(hero, 1000, dx, dy, 300)
                                    DestroyTimer(GetExpiredTimer())
                                end)
                            end
                        end

                        if GetDestructableTypeId(d) == FourCC("DTes") then
                            --print("умер кокон")
                            TimerStart(CreateTimer(), 0.4, false, function()
                                UnitDamageArea(SpiderBoss, 90, dx, dy, 120)
                                CreateUnit(GetOwningPlayer(SpiderBoss), FourCC("nspg"), dx, dy, GetRandomInt(0, 360))
                                DestroyTimer(GetExpiredTimer())
                            end)
                        end

                    end
                end
                if GetDestructableLife(d) >= 1 then
                    SetDestructableAnimation(d, "Stand Hit")
                else
                end
            end
        else
        end
    end)
    return content, contentedDest
end
