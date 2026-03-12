Script.Load("lua/Globals.lua")

Script.Load("lua/bishop/BishopUtility.lua")

Bishop.debug.FileEntry(debug.getinfo(1, "S"))

--------------------------------------------------------------------------------
-- Give bots skins for buildings, units and shoulder pads.
--------------------------------------------------------------------------------
-- They already had lifeform and marine weapon skins, but buildings were always
-- the defaults.

local function PickRandom(variants)
  return variants[variants[math.random(1, #variants)]]
end

local function SetVariants(variantData)
  -- The Gorge enums are all perfectly aligned.
  variantData.gorgeVariant = PickRandom(kGorgeVariants)
  variantData.babblerEggVariant = variantData.gorgeVariant
  variantData.babblerVariant = variantData.gorgeVariant
  variantData.clogVariant = variantData.gorgeVariant
  variantData.hydraVariant = variantData.gorgeVariant

  -- FUTURE: Pick and use skins from connected players' inventories?
  variantData.arcVariant = 1
  variantData.extractorVariant = 1
  variantData.macVariant = 1
  variantData.marineStructuresVariant = 1

  variantData.alienStructuresVariant = 1
  variantData.alienTunnelsVariant = 1
  variantData.cystVariant = 1
  variantData.drifterVariant = 1
  variantData.eggVariant = 1
  variantData.harvesterVariant = 1

  -- kShoulderPadNames is not an enum.
  variantData.shoulderPadIndex = math.random(1, #kShoulderPadNames)
end

local PlayerBot_UpdateNameAndGender = _G.PlayerBot.UpdateNameAndGender

function PlayerBot:UpdateNameAndGender()
  if not self.botSetName and self:GetPlayer() then
    PlayerBot_UpdateNameAndGender(self)
    SetVariants(self.client.variantData)
  end
end

local PlayerBot__LazilyInitBrain = _G.PlayerBot._LazilyInitBrain
function PlayerBot:_LazilyInitBrain()
  PlayerBot__LazilyInitBrain(self)

  if self.brain and not self.brain:GetSenses():GetTeamNumber() then
    local player = self:GetPlayer()
    if player then
      local teamNumber = player:GetTeamNumber()
      self.brain:GetSenses():SetTeamNumber(teamNumber)
      self.brain:GetSenses():SetParentSenses(
        GetTeamBrain(teamNumber):GetSenses())
    end
  end
end

function PlayerBot:GenerateMove()
  PROFILE("PlayerBot:GenerateMove")

  self:_LazilyInitBrain()
  local move = Move()

  -- Brain will modify move.commands and send desired motion to self.motion
  if self.brain then
    -- always clear view each frame if we have a move direction
    if self:GetMotion().desiredMoveTarget then
        self:GetMotion():SetDesiredViewTarget(nil)
    end
    self.brain:Update(self, move)
  end

  -- Now do look/wasd
  local player = self:GetPlayer()
  if player then
    self.playerEntity = player:GetId()

    if self.brain and self.brain.teamBrain and not player:GetIsAlive() then
      self.brain.teamBrain:UnassignBot(self)
      return move
    end

    local motion = self:GetMotion()
    local viewDir, moveDir, doJump = motion:OnGenerateMove(player)
    move.yaw = GetYawFromVector(viewDir) - player:GetBaseViewAngles().yaw
    move.pitch = GetPitchFromVector(viewDir)

    local xAxis, zAxis
    if not player:isa("Skulk") and not player:isa("Lerk") then
      moveDir.y = 0
      moveDir = moveDir:GetUnit()
      zAxis = Vector(viewDir.x, 0, viewDir.z):GetUnit()
      xAxis = zAxis:CrossProduct(Vector(0, -1, 0))
    else
      -- Allow Skulks and Lerks to use full 3D movement.
      xAxis = player:GetViewCoords().xAxis
      zAxis = player:GetViewCoords().zAxis
    end

    local moveX = moveDir:DotProduct(xAxis)
    local moveZ = moveDir:DotProduct(zAxis)
    move.move = GetNormalizedVector(Vector(moveX, 0, moveZ))

    if doJump then
      move.commands = AddMoveCommand(move.commands, Move.Jump)
    end

    if motion.shouldCrouch then
      motion.shouldCrouch = false
      move.commands = AddMoveCommand(move.commands, Move.Crouch)
    end
  end

  return move
end

-- Disable bot chat based on UI settings.

local Bot_SendTeamMessage = PlayerBot.SendTeamMessage

function PlayerBot:SendTeamMessage(message, extraTime, needLocalization,
    ignoreSayDelay)
  if (self:isa("CommanderBot") and not Bishop.settings.customization.botChatCom)
      or (not self:isa("CommanderBot")
      and not Bishop.settings.customization.botChat) then
    return
  end

  Bot_SendTeamMessage(self, message, extraTime, needLocalization,
    ignoreSayDelay)
end

Bishop.debug.FileExit(debug.getinfo(1, "S"))
