--=============================================================================
--
-- lua\bots\PlayerBot_Server.lua
--
-- AI "bot" functions for goal setting and moving (used by Bot.lua).
--
-- Created by Charlie Cleveland (charlie@unknownworlds.com)
-- Copyright (c) 2011, Unknown Worlds Entertainment, Inc.
--
-- Updated by Dushan, Steve, 2013. The "brain" controls the higher level logic. A lot of this code is no longer used..
--
--=============================================================================

---@class kAimDebuffState
---@field None
---@field UpHigh
---@field TooFast
kAimDebuffState = enum({
    "None",
    "UpHigh",
    "TooFast",
})

Script.Load("lua/bots/Bot.lua")
Script.Load("lua/bots/BotMotion.lua")
Script.Load("lua/bots/MarineBrain.lua")
Script.Load("lua/bots/MinigunBrain.lua")
Script.Load("lua/bots/RailgunBrain.lua")
Script.Load("lua/bots/SkulkBrain.lua")
Script.Load("lua/bots/GorgeBrain.lua")
Script.Load("lua/bots/LerkBrain.lua")
Script.Load("lua/bots/FadeBrain.lua")
Script.Load("lua/bots/OnosBrain.lua")


local kBotPersonalSettings =
{
    { name = "The Salty Sea Captain", isMale = true },
    { name = "Ashton M", isMale = true },
    { name = "Asraniel", isMale = true },
    { name = "Aazu", isMale = true },
    { name = "AxtelSturnclaw", isMale = true },
    { name = "BeigeAlert", isMale = true },
    { name = "Ballboy", isMale = true },
    { name = "Bonkers", isMale = true },
    { name = "Brackhar", isMale = true },
    { name = "Breadman", isMale = true },
    { name = "CharMomone", isMale = false },
    { name = "Chops", isMale = true },
    { name = "Clon10", isMale = false},
    { name = "Comprox", isMale = true },
    { name = "CoolCookieCooks", isMale = true },
    { name = "Crispix", isMale = true },
    { name = "Darrin F.", isMale = true },
    { name = "Decoy", isMale = false },
    { name = "Explosif.be", isMale = true },
    { name = "Flaterectomy", isMale = true },
    { name = "Flayra", isMale = true },
    { name = "GISP", isMale = true },
    { name = "GeorgiCZ", isMale = true },
    { name = "Ghoul", isMale = true },
    { name = "Handschuh", isMale = true },
    { name = "Incredulous Dylan", isMale = true },
    { name = "Insane", isMale = true },
    { name = "Ironhorse", isMale = true },
    { name = "Joev", isMale = true },
    { name = "Kash", isMale = true },
    { name = "Kopunga", isMale = true },
    { name = "Schrödinger Katz", isMale = true },
    { name = "Kouji_San", isMale = true },
    { name = "KungFuDiscoMonkey", isMale = true },
    { name = "Lachdanan", isMale = true },
    { name = "Loki", isMale = true },
    { name = "MGS-3", isMale = true },
    { name = "Matso", isMale = true },
    { name = "Mazza", isMale = true },
    { name = "McGlaspie", isMale = true },
    { name = "Mephilles", isMale = true},
    { name = "Mendasp", isMale = true },
    { name = "Michael D.", isMale = true },
    { name = "MisterOizo", isMale = true},
    { name = "MonsieurEvil", isMale = true },
    { name = "Narfwak", isMale = true },
    { name = "Numerik", isMale = true },
    { name = "Obraxis", isMale = true },
    { name = "Ooghi", isMale = true },
    { name = "OwNzOr", isMale = true },
    { name = "PaulWolfe", isMale = true},
    { name = "Patrick8675", isMale = true },
    { name = "pSyk", isMale = true },
    { name = "Railo", isMale = true },
    { name = "Rantology", isMale = false },
    { name = "Relic25", isMale = true },
    { name = "RuneStorm", isMale = false },
    { name = "Samusdroid", isMale = true },
    { name = "Salads", isMale = true },
    { name = "ScardyBob", isMale = true },
    { name = "Sinakuwolf", isMale = true },
    { name = "SnarfyBobo", isMale = true },
    { name = "SplatMan", isMale = true },
    { name = "Squeal Like a Pig", isMale = true },
    { name = "Steelcap", isMale = true },
    { name = "SteveRock", isMale = true },
    { name = "Steven G.", isMale = true },
    { name = "Strayan", isMale = true },
    { name = "Sweets", isMale = true },
    { name = "Tex", isMale = true },
    { name = "TriggerHappyBro", isMale = true },
    { name = "TychoCelchuuu", isMale = true },
    { name = "Uncle Bo", isMale = true },
    { name = "Virsoul", isMale = true },
    { name = "WDI", isMale = true },
    { name = "WasabiOne", isMale = true },
    { name = "Zaloko", isMale = true },
    { name = "Zavaro", isMale = true },
    { name = "Zefram", isMale = true },
    { name = "Zinkey", isMale = true },
    { name = "devildog", isMale = true },
    { name = "m4x0r", isMale = true },
    { name = "moultano", isMale = true },
    { name = "puzl", isMale = true },
    { name = "remi.D", isMale = true },
    { name = "sewlek", isMale = true },
    { name = "tommyd", isMale = true },
    { name = "vartija", isMale = true },
    { name = "zaggynl", isMale = true },
}

local availableBotSettings = {}

function PlayerBot:Initialize(forceTeam, active, tablePosition)
    Bot.Initialize(self, forceTeam, active, tablePosition)
end

function PlayerBot:GetPlayerOrder()
    local order
    local player = self:GetPlayer()
    if player and player.GetCurrentOrder then
        order = player:GetCurrentOrder()
    end
    return order
end

function PlayerBot:GivePlayerOrder(orderType, targetId, targetOrigin, orientation, clearExisting, insertFirst, giver)
    local player = self:GetPlayer()
    if player and player.GiveOrder then
        player:GiveOrder(orderType, targetId, targetOrigin, orientation, clearExisting, insertFirst, giver)
    end
end

function PlayerBot:GetPlayerHasOrder()
    local player = self:GetPlayer()
    if player and player.GetHasOrder then
        return player:GetHasOrder()
    end
    return false
end

function PlayerBot:GetNamePrefix()
    return "[BOT] "
end

function PlayerBot:OnEntityChange(old, new)

    if self.brain and self.brain.OnEntityChange then
        self.brain:OnEntityChange(old, new)
    end

end

function PlayerBot.GetRandomBotSetting()
    if #availableBotSettings == 0 then
        for i = 1, #kBotPersonalSettings do
            availableBotSettings[i] = i
        end

        table.shuffle(availableBotSettings)
    end

    local random = table.remove(availableBotSettings)
    return kBotPersonalSettings[random]
end

-- Personality traits that influence bots behavior to some degrees
-- aim (0-1): Decreases bot's reaction time. The reaction time generally scales based on server's avg. player skill
-- help (0-1): Increases likeliness of bots helping (guarding/welding) humans
-- aggro (0-1): Increases likeliness of bots pioritizing to attack enemies
-- sneak (bool): Should bots sneak to avoid detection by closeby enemies
local personalities =
{
    { -- new player
        aim = 0.1,
        help = 0.1,
        aggro = 0.1,
        sneaky = false,
        label = "Recruit",
    },
    { -- normal player
        aim = 0.5,
        help = 0.9,
        aggro = 0.4,
        sneaky = false,
        label = "Normal",
    },
    { -- aggesive player
        aim = 0.9,
        help = 0,
        aggro = 0.9,
        sneaky = true,  --???, not very "aggro" ...
        label = "Aggro",
    },
    { -- veteran / pro
        aim = 0.8,
        help = 0.5,
        aggro = 0.7,
        sneaky = true,
        label = "Veteran",
    },
}

-- Distribution of traits
local personalitiesDist = {1, 2, 2, 3, 4, 4}

function PlayerBot:UpdateNameAndGender()
    PROFILE("PlayerBot:UpdateNameAndGender")

    if self.botSetName then return end

    local player = self:GetPlayer()
    if not player then return end

    local name = player:GetName()
    local settings = self.GetRandomBotSetting()

    local botType = table.random(personalitiesDist)
    local botPersonality = personalities[botType]

    self.aimAbility = botPersonality.aim
    self.helpAbility = botPersonality.help
    self.aggroAbility = botPersonality.aggro
    self.sneakyAbility = botPersonality.sneaky
    self.personalityLabel = botPersonality.label       --BOT_TODO Need to wire this up to BotDebug UI, use .label field

    self.botSetName = true

    self.name = self:GetNamePrefix()..TrimName(settings.name)
    player:SetName(self.name)

    --??? Filter and prevent TD rewards?
    self.client.variantData =
    {
        isMale = settings.isMale,
        marineVariant = kMarineHumanVariants[kMarineHumanVariants[math.random(1, #kMarineHumanVariants)]],
        skulkVariant = kSkulkVariants[kSkulkVariants[math.random(1, #kSkulkVariants)]],

        gorgeVariant = kGorgeVariants[kGorgeVariants[math.random(1, #kGorgeVariants)]],
        clogVariant = 1,    --TODO Update (ideally, match Gorge-var)
        babblerEggVariant = 1,
        hydraVariant = 1,
        babblerVariant = 1,

        lerkVariant = kLerkVariants[kLerkVariants[math.random(1, #kLerkVariants)]],
        fadeVariant = kFadeVariants[kFadeVariants[math.random(1, #kFadeVariants)]],
        onosVariant = kOnosVariants[kOnosVariants[math.random(1, #kOnosVariants)]],
        rifleVariant = kRifleVariants[kRifleVariants[math.random(1, #kRifleVariants)]],
        pistolVariant = kPistolVariants[kPistolVariants[math.random(1, #kPistolVariants)]],
        axeVariant = kAxeVariants[kAxeVariants[math.random(1, #kAxeVariants)]],
        shotgunVariant = kShotgunVariants[kShotgunVariants[math.random(1, #kShotgunVariants)]],
        exoVariant = kExoVariants[kExoVariants[math.random(1, #kExoVariants)]],
        flamethrowerVariant = kFlamethrowerVariants[kFlamethrowerVariants[math.random(1, #kFlamethrowerVariants)]],
        grenadeLauncherVariant = kGrenadeLauncherVariants[kGrenadeLauncherVariants[math.random(1, #kGrenadeLauncherVariants)]],
        welderVariant = kWelderVariants[kWelderVariants[math.random(1, #kWelderVariants)]],
        hmgVariant = kHMGVariants[kHMGVariants[math.random(1, #kHMGVariants)]],

        macVariant = 1,
        arcVariant = 1,
        marineStructuresVariant = 1,
        extractorVariant = 1,

        alienStructuresVariant = 1,
        harvesterVariant = 1,
        eggVariant = 1,
        cystVariant = 1,
        drifterVariant = 1,
        alienTunnelsVariant = 1,

        shoulderPadIndex = 0
    }
    self.client:GetControllingPlayer():OnClientUpdated(self.client, false)

end

-- Just delete the bot brain when the game is reset, will trigger _LazilyInitBrain on next update
function PlayerBot:Reset()
    self.brain = nil

    local player = self:GetPlayer()
    if IsValid(player) then
        player.botBrain = nil
    end
end

function PlayerBot:_LazilyInitBrain()
    local player = self:GetPlayer()
    if not player then return end

    if self.brain == nil then

        if player:isa("Marine") then
            self.brain = MarineBrain()

        elseif player:isa("Skulk") then
            self.brain = SkulkBrain()

        elseif player:isa("Gorge") then
            self.brain = GorgeBrain()

        elseif player:isa("Lerk") then
            self.brain = LerkBrain()

        elseif player:isa("Fade") then
            self.brain = FadeBrain()

        elseif player:isa("Onos") then
            self.brain = OnosBrain()

        elseif player:isa("Exo") then   --FIXME Need to distinguish Minigun v Railgun

            local weaponHolder = player:GetActiveWeapon()
            if weaponHolder and weaponHolder:GetLeftSlotWeapon():isa("Railgun") then
                self.brain = RailgunBrain()
            else
                self.brain = MinigunBrain()
            end
        end

        --?? Add one for RR

        if self.brain ~= nil then
            self.brain:Initialize()
            player.botBrain = self.brain
            self.aim = BotAim()
            self.aim:Initialize(self)
        end

    else

        -- destroy brain if we are ready room
        if player:isa("ReadyRoomPlayer") then
            self.brain = nil
            player.botBrain = nil
        end

    end

end

local kSayTeamDelay = 20 -- don't want to make them too chatty
function PlayerBot:SendTeamMessage(message, extraTime, needLocalization, ignoreSayDelay)
    local brain = self.brain
    if not brain then return end

    if not message or type(message) ~= "string" or string.len(message) == 0 then return end

    extraTime = extraTime or 0
    local delay = ignoreSayDelay and 0 or kSayTeamDelay

    local now = Shared.GetTime()
    if not brain.timeLastSayTeam or brain.timeLastSayTeam + delay + extraTime < now then

        local chatMessage = string.UTF8Sub(message, 1, kMaxChatLength)
        local player = self:GetPlayer()
        local playerName = player:GetName()
        local playerLocationId = player.locationId
        local playerTeamNumber = player:GetTeamNumber()
        local playerTeamType = player:GetTeamType()

        local players = GetEntitiesForTeam("Player", playerTeamNumber)
        local networkMessageId = needLocalization and "ChatUnlocalized" or "Chat"
        for _, player in ipairs(players) do
            Server.SendNetworkMessage(player, networkMessageId, BuildChatMessage(true, playerName, playerLocationId, playerTeamNumber, playerTeamType, chatMessage), true)
        end

        brain.timeLastSayTeam = now
    end
end

--
-- Responsible for generating the "input" for the bot. This is equivalent to
-- what a client sends across the network.
--
function PlayerBot:GenerateMove()
    PROFILE("PlayerBot:GenerateMove")

    -- if gBotDebug:Get("spam") then
    --     Log("PlayerBot:GenerateMove")
    -- end

    self:_LazilyInitBrain()

    local move = Move()

    -- Brain will modify move.commands and send desired motion to self.motion
    if self.brain then

        -- always clear view each frame if we have a move direction
        if self:GetMotion().desiredMoveTarget then
            self:GetMotion():SetDesiredViewTarget(nil)
        end
        self.brain:Update(self,  move)

    end

    -- Now do look/wasd
    local player = self:GetPlayer()
    if player then
        self.playerEntity = player:GetId()

        if self.brain and self.brain.teamBrain and not player:GetIsAlive() then
            self.brain.teamBrain:UnassignBot(self)
            return move --bail immediately, He's dead Jim
        end

        local viewDir, moveDir, doJump = self:GetMotion():OnGenerateMove(player)

        move.yaw = GetYawFromVector(viewDir) - player:GetBaseViewAngles().yaw
        move.pitch = GetPitchFromVector(viewDir)

        moveDir.y = 0
        moveDir = moveDir:GetUnit()
        local zAxis = Vector(viewDir.x, 0, viewDir.z):GetUnit()
        local xAxis = zAxis:CrossProduct(Vector(0, -1, 0))
        local moveZ = moveDir:DotProduct(zAxis)
        local moveX = moveDir:DotProduct(xAxis)
        move.move = GetNormalizedVector(Vector(moveX, 0, moveZ))

        if doJump then
            move.commands = AddMoveCommand(move.commands, Move.Jump)
        end

    end

    return move

end

function PlayerBot:TriggerAlerts()          --FIXME Unused. Utilize/Revise, or delete
    PROFILE("PlayerBot:TriggerAlerts")

    local player = self:GetPlayer()

    local team = player:GetTeam()
    if player:isa("Marine") and team and team.TriggerAlert then

        local primaryWeapon
        local weapons = player:GetHUDOrderedWeaponList()
        if table.icount(weapons) > 0 then
            primaryWeapon = weapons[1]
        end

        -- Don't ask for stuff too often
        if not self.timeOfLastRequest or (Shared.GetTime() > self.timeOfLastRequest + 9) then

            -- Ask for health if we need it
            if player:GetHealthScalar() < .4 and (math.random() < .3) then

                team:TriggerAlert(kTechId.MarineAlertNeedMedpack, player)
                self.timeOfLastRequest = Shared.GetTime()

                -- Ask for ammo if we need it
            elseif primaryWeapon and primaryWeapon:isa("ClipWeapon") and (primaryWeapon:GetAmmo() < primaryWeapon:GetMaxAmmo()*.4) and (math.random() < .25) then

                team:TriggerAlert(kTechId.MarineAlertNeedAmmo, player)
                self.timeOfLastRequest = Shared.GetTime()

            elseif (not self:GetPlayerHasOrder()) and (math.random() < .2) then

                team:TriggerAlert(kTechId.MarineAlertNeedOrder, player)
                self.timeOfLastRequest = Shared.GetTime()

            end

        end

    end

end

function PlayerBot:GetEngagementPointOverride()
    return self:GetModelOrigin()
end

function PlayerBot:GetMotion()

    if self.motion == nil then
        self.motion = BotMotion()
        self.motion:Initialize(self:GetPlayer(), self)
    end

    return self.motion

end

function PlayerBot:OnThink()
    PROFILE("PlayerBot:OnThink")

    Bot.OnThink(self)

    self:_LazilyInitBrain()

    if not self.initializedBot then
        self.prefersAxe = (math.random() < .5)  --FIXME  ...what? So Skulks will prefer Axes? ....come on, this is just lazy bullshit
        self.inAttackRange = false
        self.initializedBot = true
    end

    self:UpdateNameAndGender()
end

-- Avoid doing expensive vis check too often by caching the results
function PlayerBot:GetBotCanSeeTarget(target)
    local targetId = target:GetId()

    if not self.visibleTargets then
        self.visibleTargets = {} --cache for target visibility checks
    end

    if not self.visibleTargets[targetId] or self.visibleTargets[targetId].validTill <= Shared.GetTime() then
        self.visibleTargets[targetId] = {
            visible = GetBotCanSeeTarget(self:GetPlayer(), target),
            validTill = Shared.GetTime() + kPlayerBrainTickFrametime
        }
    end

    return self.visibleTargets[targetId].visible
end

function PlayerBot:OnDestroy()
    Bot.OnDestroy(self)

    self.aim = nil
    self.brain = nil
    self.motion = nil

end
