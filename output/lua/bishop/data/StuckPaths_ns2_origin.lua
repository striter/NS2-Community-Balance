Bishop.debug.FileEntry(debug.getinfo(1, "S"))

kStuckData = {
--------------------------------------------------------------------------------
-- Xenoform Research window.
--------------------------------------------------------------------------------
  {
    { -- Jump from grass side.
      volume = {
        min = Vector(-36.118804931641,9.109199523926,-26.668239593506),
        max = Vector(-30.9684009552,11.876410484314,-25.429908752441)
      },
      destination = nil, -- Navmesh is fine, just needs to jump.
      flag = kStuckFlag.Jump
    },
  },

--------------------------------------------------------------------------------
-- Smelting Room.
--------------------------------------------------------------------------------
  {
    { -- West jump 1.
      volume = {
        min = Vector(-35.13744354248,5.5944000244141,87.848365783691),
        max = Vector(-25.114894866943,6.979142665863,89.614433288574)
      },
      destination = Vector(-28.78125,7.8937501907349,86.359375),
      flag = kStuckFlag.Jump
    },
    { -- West jump 2.
      volume = {
        min = Vector(-33.827297210693,5.5540071487427,81.324028015137),
        max = Vector(-25.772890090942,7.0935335159302,82.355079650879)
      },
      destination = Vector(-28.9140625,7.8937501907349,83.7421875),
      flag = kStuckFlag.Jump
    },
    { -- West escape.
      volume = {
        min = Vector(-29.890949249268,5.5962286949158,82.766975402832),
        max = Vector(-28.11279296875,7.151834487915,87.656669616699)
      },
      destination = Vector(-28.9296875,6.5578126907349,88.5390625),
      flag = kStuckFlag.None
    },
    { -- East jump 1.
      volume = {
        min = Vector(-33.885322570801,5.5965705871582,105.40000152588),
        max = Vector(-26.030910491943,7.1408495903015,106.46368408203)
      },
      destination = Vector(-31.140625,7.8859376907349,103.859375),
      flag = kStuckFlag.Jump
    },
    { -- East jump 2.
      volume = {
        min = Vector(-34.466346740723,5.5944000244141,98.59977722168),
        max = Vector(-25.014429092407,6.9965076446533,99.948753356934)
      },
      destination = Vector(-31.25,7.8859376907349,101.5078125),
      flag = kStuckFlag.Jump
    },
    { -- East escape.
      volume = {
        min = Vector(-32.403484344482,5.5060505867004,100.05531311035),
        max = Vector(-30.485570907593,6.8501543998718,105.18371582031)
      },
      destination = Vector(-31.484375,6.5500001907349,99.015625),
      flag = kStuckFlag.None
    },
  },

--------------------------------------------------------------------------------
-- Ventilation.
--------------------------------------------------------------------------------
  {
    { -- Under southern pillars.
      volume = {
        min = Vector(30.632400512695,1.228800201416,4.4443197250366),
        max = Vector(34.546031951904,5.1970872879028,17.890794754028)
      },
      destination = nil,
      flag = kStuckFlag.OnosCrouch
    },
    { -- Under northern pillars.
      volume = {
        min = Vector(52.237159729004,1.1504282951355,3.0400619506836),
        max = Vector(55.930801391602,4.5303082466125,18.557987213135)
      },
      destination = nil,
      flag = kStuckFlag.OnosCrouch
    },
    { -- East pillar with pipe.
      volume = {
        min = Vector(39.319114685059,1.2034301757813,17.199787139893),
        max = Vector(47.65238571167,5.7034301757813,20.523065567017)
      },
      destination = nil,
      flag = kStuckFlag.OnosCrouch
    },
  },
}

Bishop.debug.FileExit(debug.getinfo(1, "S"))
