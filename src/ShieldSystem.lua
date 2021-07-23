ShieldSystem = {}
function UnitAddShield(unit, amount)
    --UnitAddAbility(unit, FourCC("ACmf")) --Бафф BNms
    if not ShieldSystem[GetHandleId(unit)] then
        --rint("Щит добавлен первый раз")
        ShieldSystem[GetHandleId(unit)] = {
            IsActive = true,
        }
    end
    BlzSetUnitMaxMana(unit, amount)
    SetUnitState(unit, UNIT_STATE_MANA, amount)
end

function IsUnitHasShield(unit)
    local HasShield = false
    if not ShieldSystem[GetHandleId(unit)] then
        --	print("Щит добавлен первый раз")
        ShieldSystem[GetHandleId(unit)] = {
            IsActive = false,
        }
    end
    HasShield = ShieldSystem[GetHandleId(unit)].IsActive
    --print(HasShield)
    return HasShield
end