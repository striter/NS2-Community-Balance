Bishop.debug.FileEntry(debug.getinfo(1, "S"))

kStuckData = {
--------------------------------------------------------------------------------
-- Reactor Room.
--------------------------------------------------------------------------------
  {
    { -- Jump out of pool.
      volume = {
        min = Vector(55.447570800781,-41.166797637939,-49.937023162842),
        max = Vector(58.951061248779,-36.376045227051,-45.473640441895)
      },
      destination = Vector(57.515625,-34.43888092041,-49.8515625),
      flag = kStuckFlag.Jump
    },

    { -- Head towards jump point.
      volume = {
        min = Vector(54.889137268066,-41.826206207275,-48.945789337158),
        max = Vector(76.049674987793,-36.25830078125,-39.783115386963)
      },
      destination = Vector(57.671875,-38.606250762939,-46.859375),
      flag = kStuckFlag.None
    },

    { -- Underneath stairs east.
      volume = {
        min = Vector(75.59156036377,-38.47439956665,-59.477462768555),
        max = Vector(82.452743530273,-32.651020050049,-56.266407012939)
      },
      destination = Vector(70.734375,-31.6796875,-55.4453125),
      flag = kStuckFlag.None
    },

    { -- Underneath stairs.
      volume = {
        min = Vector(74.076240539551,-38.423599243164,-70.415893554688),
        max = Vector(82.62686920166,-35.270286560059,-59.341823577881)
      },
      destination = Vector(79.375,-35.700000762939,-57.5546875),
      flag = kStuckFlag.None
    },
  },
}

Bishop.debug.FileExit(debug.getinfo(1, "S"))
