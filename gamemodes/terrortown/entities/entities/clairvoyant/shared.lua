if SERVER then
	AddCSLuaFile()

	resource.AddFile("materials/vgui/ttt/icon_cv.vmt")
	resource.AddFile("materials/vgui/ttt/sprite_cv.vmt")
end

-- important to add roles with this function,
-- because it does more than just access the array ! e.g. updating other arrays
InitCustomRole("CLAIRVOYANT", { -- first param is access for ROLES array => CLAIRVOYANT or ROLES["CLAIRVOYANT"]
		color = Color(239, 220, 66, 255), -- ...
		dkcolor = Color(169, 152, 10, 255), -- ...
		bgcolor = Color(96, 56, 163, 255), -- ...
		name = "clairvoyant", -- just a unique name for the script to determine
		abbr = "cv", -- abbreviation
		defaultTeam = TEAM_INNOCENT, -- the team name: roles with same team name are working together
		defaultEquipment = INNO_EQUIPMENT, -- here you can set up your own default equipment
		surviveBonus = 0, -- bonus multiplier for every survive while another player was killed
		scoreKillsMultiplier = 1, -- multiplier for kill of player of another team
		scoreTeamKillsMultiplier = -8, -- multiplier for teamkill
		specialRoleFilter = true, -- enables special role filtering hook: 'TTT2_SpecialRoleFilter'; be careful: this role will be excepted from receiving every role as innocent
		unknownTeam = true -- player don't know their teammates
	}, {
		pct = 0.13, -- necessary: percentage of getting this role selected (per player)
		maximum = 1, -- maximum amount of roles in a round
		minPlayers = 8, -- minimum amount of players until this role is able to get selected
		togglable = true -- option to toggle a role for a client if possible (F1 menu)
})

-- now link this subrole with its baserole
hook.Add("TTT2BaseRoleInit", "TTT2ConBRIWithCV", function()
	SetBaseRole(CLAIRVOYANT, ROLE_INNOCENT)
end)

hook.Add("TTT2FinishedLoading", "CVInitT", function()
	if SERVER then
		if ROLES.JESTER and ROLES.SIDEKICK then -- could also be done in initialize hook
			hook.Add("TTT2SIKIAddSidekick", "CvSikiAtkHook", function(attacker, victim)
				if attacker:GetSubRole() == ROLE_CLAIRVOYANT and victim:GetSubRole() == ROLE_JESTER then
					return true
				end
			end)

			hook.Add("TTT2PreventJesterDeath", "CvSikiJesPrevDeath", function(victim)
				local attacker = victim.jesterKiller

				if IsValid(attacker) and attacker:IsPlayer() and attacker:IsActive()
				and attacker:GetSubRole() == ROLE_CLAIRVOYANT and victim:GetSubRole() == ROLE_JESTER
				then
					return true
				end
			end)
		end
	else
		-- setup here is not necessary but if you want to access the role data, you need to start here
		-- setup basic translation !
		LANG.AddToLanguage("English", CLAIRVOYANT.name, "Clairvoyant")
		LANG.AddToLanguage("English", "info_popup_" .. CLAIRVOYANT.name,
			[[You are the Clairvoyant!
            Play them all with your knowledge against each other!
            Do not talk too much about your ability, otherwise you will quickly pay for it!]])
		LANG.AddToLanguage("English", "body_found_" .. CLAIRVOYANT.abbr, "This was a Clairvoyant...")
		LANG.AddToLanguage("English", "search_role_" .. CLAIRVOYANT.abbr, "This person was a Clairvoyant!")
		LANG.AddToLanguage("English", "target_" .. CLAIRVOYANT.name, "Clairvoyant")
		LANG.AddToLanguage("English", "ttt2_desc_" .. CLAIRVOYANT.name, [[The Clairvoyant is able to see whether a player is an innocent or a player has a special role.
His goal is to survive the traitors as an innocent.

In combination with the SIDEKICK role and the JESTER role, you can kill the Jester as the only one and get a free sidekick.]])

		---------------------------------

		-- maybe this language as well...
		LANG.AddToLanguage("Deutsch", CLAIRVOYANT.name, "Hellseher")
		LANG.AddToLanguage("Deutsch", "info_popup_" .. CLAIRVOYANT.name,
			[[Du bist DER Hellseher!
            Spiele sie ALLE mit deinem Wissen gegeneinander aus!
            Gebe nicht zu viel von deiner Fähigkeit preis, sonst wirst du schnell dafür bezahlen!]])
		LANG.AddToLanguage("Deutsch", "body_found_" .. CLAIRVOYANT.abbr, "Er war ein Hellseher...")
		LANG.AddToLanguage("Deutsch", "search_role_" .. CLAIRVOYANT.abbr, "Diese Person war ein Hellseher!")
		LANG.AddToLanguage("Deutsch", "target_" .. CLAIRVOYANT.name, "Hellseher")
		LANG.AddToLanguage("Deutsch", "ttt2_desc_" .. CLAIRVOYANT.name, [[Der Hellseher kann sehen, ob ein Spieler ein normaler Unschuldiger ist
oder ob ein Spieler eine spezielle Rolle hat.
Sein Ziel ist es als ein Unschuldiger zu überleben.

In Kombination mit der SIDEKICK Rolle und der JESTER Rolle bekommst du automatisch einen Sidekick, sobald du den Jester gekillt hast.]])
	end
end)

if SERVER then
	util.AddNetworkString("TTT2CVSpecialRole")

	hook.Add("TTT2SpecialRoleSyncing", "CVRoleFilter", function(ply)
		local tmp = {}
		local plys = (IsValid(ply) and ply:IsPlayer() and ply:GetSubRole() == ROLE_CLAIRVOYANT) and {ply} or GetSubRoleFilter(ROLE_CLAIRVOYANT)

		for _, v in ipairs(player.GetAll()) do
			local subrole = v:GetSubRole()

			if v:IsActive() and subrole ~= ROLE_INNOCENT and subrole ~= ROLE_TRAITOR and not table.HasValue(plys, v) then
				tmp[#tmp + 1] = v:EntIndex()
			end
		end

		for _, v in ipairs(plys) do
			net.Start("TTT2CVSpecialRole")
			net.WriteUInt(#tmp, 8)

			for _, eidx in ipairs(tmp) do
				net.WriteUInt(eidx, 16) -- 16 bits
			end

			net.Send(v)
		end
	end)
else -- CLIENT
	hook.Add("TTTScoreboardRowColorForPlayer", "TTT2CVColoredScoreboard", function(ply)
		local client = LocalPlayer()

		if client:GetSubRole() == ROLE_CLAIRVOYANT
		and ply ~= client
		and not ply:GetForceSpec()
		and ply.cv_specialRole
		and not ply:IsSpecial()
		then
			return Color(204, 153, 255, 255)
		end
	end)

	net.Receive("TTT2CVSpecialRole", function(len)
		local amount = net.ReadUInt(8)
		local rs = GetRoundState()

		if amount > 0 then
			for i = 1, amount do
				local ply = Entity(net.ReadUInt(16))

				if rs == ROUND_ACTIVE and IsValid(ply) and ply:IsPlayer() then
					ply.cv_specialRole = true
				end
			end
		end
	end)

	hook.Add("TTTEndRound", "TTT2CVEntRound", function()
		for _, v in ipairs(player.GetAll()) do
			v.cv_specialRole = false
		end
	end)
end
