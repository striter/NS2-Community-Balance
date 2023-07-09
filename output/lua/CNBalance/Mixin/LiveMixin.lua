LiveMixin.kMaxHealth = 8191 -- 2^13-1, Maximum possible value for maxHealth
LiveMixin.kMaxArmor  = 4095 -- 2^12-1, Maximum possible value for maxArmor

LiveMixin.networkVars.armor =  string.format("float (0 to %f by 0.0625)", LiveMixin.kMaxArmor)
LiveMixin.networkVars.maxArmor = string.format("integer (0 to %f)", LiveMixin.kMaxArmor)
LiveMixin.networkVars.health =  string.format("float (0 to %f by 0.0625)", LiveMixin.kMaxHealth)
LiveMixin.networkVars.maxHealth = string.format("integer (0 to %f)", LiveMixin.kMaxHealth)