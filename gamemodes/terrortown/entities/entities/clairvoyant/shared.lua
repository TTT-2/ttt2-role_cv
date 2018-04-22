AddCSLuaFile()

if SERVER then
   resource.AddFile("materials/vgui/ttt/icon_cv.vmt")
   resource.AddFile("materials/vgui/ttt/sprite_cv.vmt")
end

-- important to add roles with this function,
-- because it does more than just access the array ! e.g. updating other arrays
AddCustomRole("CLAIRVOYANT", { -- first param is access for ROLES array => ROLES.CLAIRVOYANT or ROLES["CLAIRVOYANT"]
	color = Color(239, 220, 66, 255), -- ...
	dkcolor = Color(120, 135, 33, 255), -- ...
	bgcolor = Color(0, 50, 0, 200), -- ...
	name = "clairvoyant", -- just a unique name for the script to determine
	printName = "Clairvoyant", -- The text that is printed to the player, e.g. in role alert
	abbr = "cv", -- abbreviation
	team = "clairvoyants", -- the team name: roles with same team name are working together
	defaultEquipment = INNO_EQUIPMENT, -- here you can set up your own default equipment
    specialRoleFilter = true, -- enables special role filtering hook: 'TTT2_SpecialRoleFilter'; be careful: this role will be excepted from receiving every role as innocent
    surviveBonus = 0, -- bonus multiplier for every survive while another player was killed
    scoreKillsMultiplier = 1, -- multiplier for kill of player of another team
    scoreTeamKillsMultiplier = -8 -- multiplier for teamkill
}, {
    pct = 0.13, -- necessary: percentage of getting this role selected (per player)
    maximum = 1, -- maximum amount of roles in a round
    minPlayers = 8, -- minimum amount of players until this role is able to get selected
    togglable = true -- option to toggle a role for a client if possible (F1 menu)
})

hook.Add("TTT2_FinishedSync", "CVInitT", function(ply, first)
    if CLIENT and first then -- just on client and first init !

        -- setup here is not necessary but if you want to access the role data, you need to start here
        -- setup basic translation !
        LANG.AddToLanguage("English", ROLES.CLAIRVOYANT.name, "Clairvoyant")
        LANG.AddToLanguage("English", "hilite_win_" .. ROLES.CLAIRVOYANT.name, "THE CV WON") -- name of base role of a team -> maybe access with GetTeamRoles(ROLES.CLAIRVOYANT.team)[1].name
        LANG.AddToLanguage("English", "win_" .. ROLES.CLAIRVOYANT.team, "The Clairvoyant has won!") -- teamname
        LANG.AddToLanguage("English", "info_popup_" .. ROLES.CLAIRVOYANT.name, 
            [[You are the Clairvoyant! 
            Play them all with your knowledge against each other!
            Do not talk too much about your ability, otherwise you will quickly pay for it!]])
        LANG.AddToLanguage("English", "body_found_" .. ROLES.CLAIRVOYANT.abbr, "This was a Clairvoyant...")
        LANG.AddToLanguage("English", "search_role_" .. ROLES.CLAIRVOYANT.abbr, "This person was a Clairvoyant!")
        LANG.AddToLanguage("English", "ev_win_" .. ROLES.CLAIRVOYANT.abbr, "The enlightened Clairvoyant won the round!")
		LANG.AddToLanguage("English", "target_" .. ROLES.CLAIRVOYANT.name, "Clairvoyant")
        
        -- optional for toggling whether player can avoid the role
        LANG.AddToLanguage("English", "set_avoid_" .. ROLES.CLAIRVOYANT.abbr, "Avoid being selected as Clairvoyant!")
        LANG.AddToLanguage("English", "set_avoid_" .. ROLES.CLAIRVOYANT.abbr .. "_tip", 
            [[Enable this to ask the server not to select you as Clairvoyant if possible. Does not mean you are Traitor more often.]])
        
        ---------------------------------

        -- maybe this language as well...
        LANG.AddToLanguage("Deutsch", ROLES.CLAIRVOYANT.name, "Hellseher")
        LANG.AddToLanguage("Deutsch", "hilite_win_" .. ROLES.CLAIRVOYANT.name, "THE CV WON")
        LANG.AddToLanguage("Deutsch", "win_" .. ROLES.CLAIRVOYANT.team, "Der Hellseher hat gewonnen!")
        LANG.AddToLanguage("Deutsch", "info_popup_" .. ROLES.CLAIRVOYANT.name, 
            [[Du bist DER Hellseher! 
            Spiele sie ALLE mit deinem Wissen gegeneinander aus!
            Gebe nicht zu viel von deiner Fähigkeit preis, sonst wirst du schnell dafür bezahlen!]])
        LANG.AddToLanguage("Deutsch", "body_found_" .. ROLES.CLAIRVOYANT.abbr, "Er war ein Hellseher...")
        LANG.AddToLanguage("Deutsch", "search_role_" .. ROLES.CLAIRVOYANT.abbr, "Diese Person war ein Hellseher!")
        LANG.AddToLanguage("Deutsch", "ev_win_" .. ROLES.CLAIRVOYANT.abbr, "Der erleuchtete Hellseher hat die Runde gewonnen!")
		LANG.AddToLanguage("Deutsch", "target_" .. ROLES.CLAIRVOYANT.name, "Hellseher")
        
        LANG.AddToLanguage("Deutsch", "set_avoid_" .. ROLES.CLAIRVOYANT.abbr, "Vermeide als Hellseher ausgewählt zu werden!")
        LANG.AddToLanguage("Deutsch", "set_avoid_" .. ROLES.CLAIRVOYANT.abbr .. "_tip", 
            [[Aktivieren, um beim Server anzufragen, nicht als Hellseher ausgewählt zu werden. Das bedeuted nicht, dass du öfter Traitor wirst!]])
    elseif SERVER and first then
        if ROLES.JESTER and ROLES.SIDEKICK then
            hook.Add("TTT2_SIKI_CanAttackerSidekick", "CvSikiAtkHook", function(attacker, victim)
                return attacker:GetRole() == ROLES.CLAIRVOYANT.index and victim:GetRole() == ROLES.JESTER.index
            end)
        end
    end
end)

if SERVER then
    hook.Add("TTT2_SpecialRoleFilter", "CVRoleFilter", function(ply)
        for _, v in pairs(ROLES) do -- allow clairvoyant to receive the specific role of each player
            if not ROLES.SIDEKICK or ROLES.SIDEKICK and v ~= ROLES.SIDEKICK then 
                SendRoleList(v.index, ply ~= nil and ply or GetPlayerFilter(function(p) 
                    return p:IsRole(ROLES.CLAIRVOYANT.index) 
                end))
            end
        end
    end)
else -- CLIENT
    -- TODO improve performance
    --[[
    hook.Add("PreDrawHalos", "AddCVHalos", function()
       local client = LocalPlayer()

       if client:GetRole() == ROLES.CLAIRVOYANT.index then
          -- create table for each role
          local tmp = {}

          for _, v in pairs(ROLES) do
             tmp[v.index] = {}
          end

          for _, v in pairs(player.GetAll()) do
             if v ~= client and v:Alive() then
                table.insert(tmp[v:GetRoleData().index], v)
             end
          end
          
          for k, _ in pairs(tmp) do
             halo.Add(tmp[k], GetRoleByIndex(k).color, 0, 0, 2, true, false)
          end
       end
    end)
    ]]--
    
    indicator_col = Color(255, 255, 255, 130)
    indicator_mat_tbl = {}

    hook.Add("TTT2_FinishedSync", "updateCVData", function(ply, first)
        if first then
            indicator_mat_tbl = {}

            for _, v in pairs(ROLES) do
                local mat = Material("vgui/ttt/sprite_" .. v.abbr)

                indicator_mat_tbl[v.index] = mat
            end
        end
    end)
    
    function GetPlayers()
        local tmp = {}
    
        for _, v in pairs(player.GetAll()) do
            if v:IsActive() then
                table.insert(tmp, v)
            end
        end
        
        return tmp
    end
    
    hook.Add("PostDrawTranslucentRenderables", "PostDrawCVTrabsRend", function()
        local client, pos, dir
        
        client = LocalPlayer()
        
        local trace = client:GetEyeTrace(MASK_SHOT)
        local ent = trace.Entity

        if not IsValid(ent) or ent.NoTarget or not ent:IsPlayer() then return end

        if client:GetRole() == ROLES.CLAIRVOYANT.index then
            dir = (client:GetForward() * -1)

            pos = ent:GetPos()
            pos.z = (pos.z + 74)

            if ent ~= client then
                if ent:IsActive() then
                    local mat = indicator_mat_tbl[ent:GetRole()]
                    
                    render.SetMaterial(mat)
                    render.DrawQuadEasy(pos, dir, 8, 8, indicator_col, 180)
                end
            end
        end
    end)
end
