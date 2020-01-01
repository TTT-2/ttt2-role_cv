if SERVER then
	AddCSLuaFile()

	resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_cv.vmt")
end

function ROLE:PreInitialize()
	self.color = Color(94, 76, 118, 255)

	self.abbr = "cv" -- abbreviation
	self.surviveBonus = 0 -- bonus multiplier for every survive while another player was killed
	self.scoreKillsMultiplier = 1 -- multiplier for kill of player of another team
	self.scoreTeamKillsMultiplier = -8 -- multiplier for teamkill
	self.specialRoleFilter = true -- enables special role filtering hook: 'TTT2_SpecialRoleFilter'; be careful: this role will be excepted from receiving every role as innocent
	self.unknownTeam = true -- player don't know their teammates

	self.defaultTeam = TEAM_INNOCENT
	self.defaultEquipment = INNO_EQUIPMENT -- here you can set up your own default equipment

	self.conVarData = {
		pct = 0.13, -- necessary: percentage of getting this role selected (per player)
		maximum = 1, -- maximum amount of roles in a round
		minPlayers = 8, -- minimum amount of players until this role is able to get selected
		togglable = true -- option to toggle a role for a client if possible (F1 menu)
	}
end

function ROLE:Initialize()
	roles.SetBaseRole(self, ROLE_INNOCENT)

	if SERVER then
		if JESTER and SIDEKICK then -- could also be done in initialize hook
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
		LANG.AddToLanguage("English", self.name, "Clairvoyant")
		LANG.AddToLanguage("English", "info_popup_" .. self.name,
			[[You are the Clairvoyant!
			Play them all with your knowledge against each other!
			Do not talk too much about your ability, otherwise you will quickly pay for it!]])
		LANG.AddToLanguage("English", "body_found_" .. self.abbr, "This was a Clairvoyant...")
		LANG.AddToLanguage("English", "search_role_" .. self.abbr, "This person was a Clairvoyant!")
		LANG.AddToLanguage("English", "target_" .. self.name, "Clairvoyant")
		LANG.AddToLanguage("English", "ttt2_desc_" .. self.name, [[The Clairvoyant is able to see whether a player is an innocent or a player has a special role.
His goal is to survive the traitors as an innocent.

In combination with the SIDEKICK role and the JESTER role, you can kill the Jester as the only one and get a free sidekick.]])

		---------------------------------

		-- maybe this language as well...
		LANG.AddToLanguage("Deutsch", self.name, "Hellseher")
		LANG.AddToLanguage("Deutsch", "info_popup_" .. self.name,
			[[Du bist DER Hellseher!
			Spiele sie ALLE mit deinem Wissen gegeneinander aus!
			Gebe nicht zu viel von deiner Fähigkeit preis, sonst wirst du schnell dafür bezahlen!]])
		LANG.AddToLanguage("Deutsch", "body_found_" .. self.abbr, "Er war ein Hellseher...")
		LANG.AddToLanguage("Deutsch", "search_role_" .. self.abbr, "Diese Person war ein Hellseher!")
		LANG.AddToLanguage("Deutsch", "target_" .. self.name, "Hellseher")
		LANG.AddToLanguage("Deutsch", "ttt2_desc_" .. self.name, [[Der Hellseher kann sehen, ob ein Spieler ein normaler Unschuldiger ist
oder ob ein Spieler eine spezielle Rolle hat.
Sein Ziel ist es als ein Unschuldiger zu überleben.

In Kombination mit der SIDEKICK Rolle und der JESTER Rolle bekommst du automatisch einen Sidekick, sobald du den Jester gekillt hast.]])
	end
end

hook.Add("TTTUlxDynamicRCVars", "TTTUlxDynamicCvCVars", function(tbl)
	tbl[ROLE_CLAIRVOYANT] = tbl[ROLE_CLAIRVOYANT] or {}

	table.insert(tbl[ROLE_CLAIRVOYANT], {cvar = "ttt2_cv_visible", slider = true, min = 1, max = 100, desc = "Sets the percentage of visible player's roles"})
end)

local cachedTable = nil

if SERVER then
	util.AddNetworkString("TTT2CVSpecialRole")

	local ttt2_cv_visible = CreateConVar("ttt2_cv_visible", "100", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Sets the percentage of visible player's roles")

	hook.Add("TTT2SpecialRoleSyncing", "CVRoleFilter", function(ply)
		if not cachedTable then return end

		local plys = (IsValid(ply) and ply:IsPlayer() and ply:GetSubRole() == ROLE_CLAIRVOYANT) and {ply} or GetSubRoleFilter(ROLE_CLAIRVOYANT)

		for _, v in ipairs(plys) do
			net.Start("TTT2CVSpecialRole")
			net.WriteUInt(#cachedTable, 8)

			for _, eidx in ipairs(cachedTable) do
				net.WriteUInt(eidx, 16) -- 16 bits
			end

			net.Send(v)
		end
	end)

	hook.Add("TTTEndRound", "TTT2CVEndRound", function()
		cachedTable = nil
	end)

	hook.Add("TTTBeginRound", "TTT2CVBeginRound", function()
		local plys = (IsValid(ply) and ply:IsPlayer() and ply:GetSubRole() == ROLE_CLAIRVOYANT) and {ply} or GetSubRoleFilter(ROLE_CLAIRVOYANT)
		local tmp = {}

		for _, v in ipairs(player.GetAll()) do
			if not v:IsActive() or not v:IsTerror() then continue end

			local subrole = v:GetSubRole()

			if subrole ~= ROLE_INNOCENT and subrole ~= ROLE_TRAITOR and v:GetBaseRole() ~= ROLE_DETECTIVE and not table.HasValue(plys, v) then
				tmp[#tmp + 1] = v:EntIndex()
			end
		end

		local tmp2 = tmp

		local cvrand = ttt2_cv_visible:GetInt()
		if cvrand < 100 then
			-- now calculate amount of visible roles
			local tmpCount = #tmp
			local activeAmount = math.min(math.ceil(tmpCount * (cvrand * 0.01)), tmpCount)

			-- now randomize the new list
			if tmpCount ~= activeAmount then
				tmp2 = {}

				for i = 1, activeAmount do
					local val = math.random(1, #tmp)

					tmp2[i] = tmp[val]

					table.remove(tmp, val)
				end
			end
		end

		cachedTable = tmp2
	end)
end

if CLIENT then
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

	net.Receive("TTT2CVSpecialRole", function()
		-- reset
		for _, v in ipairs(player.GetAll()) do
			v.cv_specialRole = nil
		end

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

	hook.Add("TTTEndRound", "TTT2CVEndRound", function()
		for _, v in ipairs(player.GetAll()) do
			v.cv_specialRole = nil
		end
	end)
end
