AddCSLuaFile()

if SERVER then
   resource.AddFile("materials/vgui/ttt/icon_cv.vmt")
   resource.AddFile("materials/vgui/ttt/sprite_cv.vmt")
end

-- important to add roles with this function,
-- because it does more than just access the array ! e.g. updating other arrays
AddCustomRole("CLAIRVOYANT", { -- first param is access for ROLES array => ROLES.CLAIRVOYANT or ROLES["CLAIRVOYANT"]
	color = Color(255, 255, 102, 255), -- ...
	dkcolor = Color(230, 230, 0, 255), -- ...
	bgcolor = Color(0, 50, 0, 200), -- ...
	name = "clairvoyant", -- just a unique name for the script to determine
	printName = "Clairvoyant", -- The text that is printed to the player, e.g. in role alert
	abbr = "cv", -- abbreviation
	shop = false, -- can the role access the [C] shop ?
	team = "clairvoyants", -- the team name: roles with same team name are working together
	defaultEquipment = INNO_EQUIPMENT, -- here you can set up your own default equipment
	visibleForTraitors = false, -- other traitors can see this role / sync them with traitors / not necessary if role is in TEAM_TRAITOR
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

-- if sync of roles has finished
if CLIENT then
    hook.Add("TTT2_FinishedSync", "CVInitT", function(first)
        if first then -- just on client and first init !

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
            
            LANG.AddToLanguage("Deutsch", "set_avoid_" .. ROLES.CLAIRVOYANT.abbr, "Vermeide als Hellseher ausgewählt zu werden!")
            LANG.AddToLanguage("Deutsch", "set_avoid_" .. ROLES.CLAIRVOYANT.abbr .. "_tip", 
                [[Aktivieren, um beim Server anzufragen, nicht als Hellseher ausgewählt zu werden. Das bedeuted nicht, dass du öfter Traitor wirst!]])
        end
    end)
end

if SERVER then

    -- function in gamemsg.lua
    local function GetPlayerFilter(pred)
        local filter = {}

        for _, v in pairs(player.GetAll()) do
            if IsValid(v) and pred(v) then
                table.insert(filter, v)
            end
        end

        return filter
    end

    -- function in traitor_state.lua
    function SendRoleListMessage(role, role_ids, ply_or_rf)
        net.Start("TTT_RoleList")
        net.WriteUInt(role - 1, ROLE_BITS)

        -- list contents
        local num_ids = #role_ids

        net.WriteUInt(num_ids, 8)

        for i = 1, num_ids do
            net.WriteUInt(role_ids[i] - 1, 7)
        end

        if ply_or_rf then 
            net.Send(ply_or_rf)
        else 
            net.Broadcast() 
        end
    end

    -- function in traitor_state.lua
    function SendRoleList(role, ply_or_rf, pred)
        local role_ids = {}

        for _, v in pairs(player.GetAll()) do
            if v:IsRole(role) then
                if not pred or (pred and pred(v)) then
                    table.insert(role_ids, v:EntIndex())
                end
            end
        end

        SendRoleListMessage(role, role_ids, ply_or_rf)
    end
    
    hook.Add("TTT2_SpecialRoleFilter", "CVRoleFilter", function(ply)
        for _, v in pairs(ROLES) do -- allow clairvoyant to receive the specific role of each player
            SendRoleList(v.index, ply ~= nil and ply or GetPlayerFilter(function(p) 
                return p:IsRole(ROLES.CLAIRVOYANT.index) 
            end))
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

    hook.Add("TTT2_FinishedSync", "updateCVData", function(first)
        indicator_mat_tbl = {}

        for _, v in pairs(ROLES) do
            local mat = Material("vgui/ttt/sprite_" .. v.abbr)

            indicator_mat_tbl[v.index] = mat
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
        local client, plys, ply, pos, dir
        
        client = LocalPlayer()
        plys = GetPlayers()

        if client:GetRole() == ROLES.CLAIRVOYANT.index then
            dir = (client:GetForward() * -1)

            for i = 1, #plys do
                ply = plys[i]

                pos = ply:GetPos()
                pos.z = (pos.z + 74)

                if ply ~= client then
                    --if ply:IsActive() then -- check not necessary because just active players had been inserted into array
                        local mat = indicator_mat_tbl[ply:GetRole()]
                        if mat == nil then
                            print("Mat is nil in CV: " .. ply:GetRole())
                        end
                        render.SetMaterial(mat)
                        render.DrawQuadEasy(pos, dir, 8, 8, indicator_col, 180)
                    --end
                end
            end
        end
    end)
end
