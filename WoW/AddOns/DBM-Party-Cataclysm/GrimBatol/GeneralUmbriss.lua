local mod	= DBM:NewMod(131, "DBM-Party-Cataclysm", 3, 71)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 145 $"):sub(12, -3))
mod:SetCreatureID(39625)
mod:SetZone()

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED",
	"SPELL_AURA_APPLIED_DOSE",
	"SPELL_AURA_REMOVED",
	"SPELL_CAST_START",
	"UNIT_HEALTH",
	"CHAT_MSG_RAID_BOSS_EMOTE"
)

local warnBleedingWound		= mod:NewTargetAnnounce(74846, 4, nil, "Tank|Healer")
local warnMalady			= mod:NewTargetAnnounce(74837, 2)
local warnMalice			= mod:NewSpellAnnounce(90170, 4)
local warnFrenzySoon		= mod:NewSoonAnnounce(74853, 2, nil, "Tank|Healer")
local warnFrenzy			= mod:NewSpellAnnounce(74853, 3, nil, "Tank|Healer")
local warnBlitz				= mod:NewTargetAnnounce(74670, 4)

local specWarnMalice		= mod:NewSpecialWarningSpell(90170, "Tank")
local specWarnBlitz			= mod:NewSpecialWarningYou(74670)

local timerBleedingWound	= mod:NewTargetTimer(15, 74846, nil, "Tank|Healer")
local timerBleedingWoundCD	= mod:NewCDTimer(25, 74846, nil, "Tank|Healer")
local timerGroundSiege		= mod:NewCastTimer(2, 74634, nil, "Healer|Melee")
local timerBlitz			= mod:NewCDTimer(23, 74670)
local timerMalady			= mod:NewBuffFadesTimer(10, 74837)
local timerMalice			= mod:NewBuffActiveTimer(20, 90170)

mod:AddBoolOption("PingBlitz")

local warnedFrenzy
local maladyTargets = {}
local maladyCount = 0

local function showMaladyWarning()
	warnMalady:Show(table.concat(maladyTargets, "<, >"))
	table.wipe(maladyTargets)
	timerMalady:Start()
end

function mod:OnCombatStart(delay)
	warnedFrenzy = false
	table.wipe(maladyTargets)
	maladyCount = 0
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 74846 then
		warnBleedingWound:Show(args.destName)
		timerBleedingWound:Start(args.destName)
		timerBleedingWoundCD:Start()
	elseif args.spellId == 74853 then
		warnFrenzy:Show()
	elseif args.spellId == 74837 then
		maladyCount = maladyCount + 1
		maladyTargets[#maladyTargets + 1] = args.destName
		self:Unschedule(showMaladyWarning)
		self:Schedule(0.3, showMaladyWarning)
	elseif args.spellId == 90170 then
		warnMalice:Show()
		specWarnMalice:Show()
		timerMalice:Start()
	end
end

mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == 74846 then
		timerBleedingWound:Cancel(args.destName)
	elseif args.spellId == 74837 then
		maladyCount = maladyCount - 1
		if maladyCount == 0 then
			timerMalady:Cancel()
		end
	end
end

function mod:SPELL_CAST_START(args)
	if args.spellId == 74634 then
		timerGroundSiege:Start()
	end
end

function mod:UNIT_HEALTH(uId)
	if UnitName(uId) == L.name then
		local h = UnitHealth(uId) / UnitHealthMax(uId) * 100
		if warnedFrenzy and h > 50 then
			warnedFrenzy = false
		elseif h > 33 and h < 38 and not warnedFrenzy then
			warnFrenzySoon:Show()
			warnedFrenzy = true
		end
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg, _, _, _, target)
	if msg:find(L.Blitz) then
		timerBlitz:Start()
		if target then
			local target = DBM:GetUnitFullName(target)
			warnBlitz:Show(target)
			if target == UnitName("player") then
				specWarnBlitz:Show()
				if self.Options.PingBlitz then
					Minimap:PingLocation()
				end
			end
		end
	end
end
