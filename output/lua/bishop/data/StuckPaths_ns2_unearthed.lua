Bishop.debug.FileEntry(debug.getinfo(1, "S"))

kStuckData = {
--------------------------------------------------------------------------------
-- Junction.
--------------------------------------------------------------------------------
  {
    { -- South-east next to catwalk.
      volume = {
        min = Vector(97.082862854004,27.81955909729,98.497901916504),
        max = Vector(102.59215545654,34.576347351074,103.09586334229)
      },
      destination = Vector(97.2734375,35.815624237061,99.7109375),
      flag = kStuckFlag.Jump
    },

    { -- South-east jump back to catwalk.
      volume = {
        min = Vector(97.131942749023,34.094058990479,98.503112792969),
        max = Vector(101.0630569458,36.86478805542,102.24494934082)
      },
      destination = Vector(97.703125,34.456249237061,95.1640625),
      flag = kStuckFlag.None
    },

    { -- East side move down towards stairs.
      volume = {
        min = Vector(102.3907699585,27.751970291138,97.900611877441),
        max = Vector(107.49028778076,32.075710296631,103.05424499512)
      },
      destination = Vector(99.5859375,32.660938262939,101.90625),
      flag = kStuckFlag.AndOnosCrouch
    },

    { -- Underneath move west.
      volume = { -- 99 to 94 (south?)
        min = Vector(94.330055236816,27.375318527222,84.773681640625),
        max = Vector(102.70833587646,32.165191650391,98.132102966309)
      },
      destination = Vector(101.484375,30.331249237061,82.1796875),
      flag = kStuckFlag.AndOnosCrouch
    },

    { -- Underneath move south.
      volume = {
        min = Vector(102.36279296875,27.26718711853,93.413360595703),
        max = Vector(107.49028015137,32.086780548096,98.685745239258)
      },
      destination = Vector(102.0234375,29.026561737061,94.734375),
      flag = kStuckFlag.AndOnosCrouch
    },

    { -- Stuck under west stairs.
      volume = {
        min = Vector(102.9359664917,27.956407546997,87.924270629883),
        max = Vector(105.67150115967,30.755584716797,94.405029296875)
      },
      destination = Vector(100.109375,30.768749237061,89.0859375),
      flag = kStuckFlag.None
    },
  },

--------------------------------------------------------------------------------
-- Mining Tunnel.
--------------------------------------------------------------------------------
  {
    { -- Under catwalk escape.
      volume = {
        min = Vector(142.56132507324,27.211828231812,10.809560775757),
        max = Vector(146.5754699707,30.457149505615,13.047222137451)
      },
      destination = Vector(147.515625,29.956249237061,11.875),
      flag = kStuckFlag.None
    },

    { -- Mini catwalk jump.
      volume = {
        min = Vector(139.82698059082,27.237594604492,8.4733877182007),
        max = Vector(149.2758026123,30.434122085571,15.264022827148)
      },
      destination = Vector(144.609375,32.364265441895,11.859375),
      flag = kStuckFlag.Jump
    },
  },

--------------------------------------------------------------------------------
-- Stuck underneath Passage.
--------------------------------------------------------------------------------
  {
    { -- Derped underneath ramp.
      volume = {
        min = Vector(180.89772033691,26.502155303955,164.81575012207),
        max = Vector(183.13400268555,28.690643310547,167.94929504395)
      },
      destination = Vector(178.9921875,28.174999237061,166.421875),
      flag = kStuckFlag.NoSkulk
    },

    { -- Final ramp jump.
      volume = {
        min = Vector(180.74591064453,29.411935806274,164.41279602051),
        max = Vector(183.13400268555,31.327600479126,168.09509277344)
      },
      destination = Vector(178.8359375,30.878124237061,165.625),
      flag = kStuckFlag.NoSkulkJump
    },

    { -- Up the ramp.
      volume = {
        min = Vector(180.84799194336,26.384370803833,160.99749755859),
        max = Vector(183.06715393066,31.051761627197,166.24565124512)
      },
      destination = Vector(182,30.573436737061,167.109375),
      flag = kStuckFlag.NoSkulk
    },

    { -- Properly underneath.
      volume = {
        min = Vector(163.64334106445,26.423910140991,164.04357910156),
        max = Vector(183.13400268555,29.123918533325,170.2297668457)
      },
      destination = Vector(178.99415588379,28.739698410034,160.80740356445),
      flag = kStuckFlag.NoSkulk
    },

    { -- Head towards ramp.
      volume = {
        min = Vector(164.64094543457,26.366094589233,160.90296936035),
        max = Vector(183.13400268555,30.031856536865,165.95846557617)
      },
      destination = Vector(183.13400268555,28.644109725952,161.8490447998),
      flag = kStuckFlag.NoSkulk
    },
  },
}

Bishop.debug.FileExit(debug.getinfo(1, "S"))
