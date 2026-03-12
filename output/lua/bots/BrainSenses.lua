
------------------------------------------
--  STEVE TODO: Should refactor this so a senses state is different from senses functions.
--  So we can hotload the functions without recreating it each frame.
------------------------------------------
class "BrainSenses"

-- Chatnachrichtenzähler
gLastAlienReports = gLastAlienReports or {}
gLastMarineReports = gLastMarineReports or {}

function BrainSenses:Initialize()

    self.name2eval = {}

    -- per-frame state
    self.name2value = {}
    self.name2evaling = {}
    self.bot = nil

end

function BrainSenses:Add(senseName, evalFunc)
    self.name2eval[ senseName ] = evalFunc
end

function BrainSenses:OnBeginFrame(bot)

    self.name2value = {}
    self.name2evaling = {}
    self.bot = bot

    if bot then
        self.player = bot:GetPlayer()
    else
        self.player = nil
    end

end

function BrainSenses:GetDebugTrace()
    return self.debugTrace
end

------------------------------------------
--  Call this before passing in the senses to a new weight evaluator
------------------------------------------
function BrainSenses:ResetDebugTrace()
    self.debugTrace = ""
end

function BrainSenses:Get(senseName)
    local value = self.name2value[ senseName ]

    if value == nil then

        -- Check for cycles
        assert( self.name2evaling[senseName] == nil )

        local evalFunc = self.name2eval[ senseName ]
        assert( evalFunc ~= nil )

        self.name2evaling[ senseName ] = true
        value = evalFunc( self, self.player )
        self.name2evaling[ senseName ] = nil
        self.name2value[ senseName ] = value

    end

    if not self.debugTrace then return value end

    local oldTrace = self.debugTrace
    self.debugTrace = ""

    self.debugTrace = string.format( "%s%s = %s%s",
            oldTrace == "" and "" or oldTrace..", ",
            senseName,
            ToString(value),
            self.debugTrace == "" and "" or " ("..self.debugTrace..")" )

    return value
end

