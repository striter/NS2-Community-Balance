Bishop.debug.FileEntry(debug.getinfo(1, "S"))

kStuckData = {
--------------------------------------------------------------------------------
-- System Waypointing.
--------------------------------------------------------------------------------
  {
    { -- North vent entrance.
      volume = {
        min = Vector(-29.146745681763,-3.8071675300598,-117.5154876709),
        max = Vector(-26.195899963379,-1.1382628679276,-114.02059936523)
      },
      destination = Vector(-23.671875,-1.7546875476837,-115.9453125),
      flag = kStuckFlag.NoSkulk
    },

    { -- South vent entrance.
      volume = {
        min = Vector(-36.274955749512,-3.8044447898865,-117.98300170898),
        max = Vector(-32.7854347229,-1.0668001174927,-114.40033721924)
      },
      destination = Vector(-37.3125,-1.7390625476837,-116.140625),
      flag = kStuckFlag.NoSkulk
    },
  },

--------------------------------------------------------------------------------
-- System Waypointing north.
--------------------------------------------------------------------------------
  {
    { -- Somehow under the floor.
      volume = {
        min = Vector(-14.456774711609,-5.0271172523499,-134.16494750977),
        max = Vector(-11.825015068054,-2.8250317573547,-126.48986053467)
      },
      destination = Vector(-13.09375,-3.4812500476837,-136.4765625),
      flag = kStuckFlag.NoSkulk
    },

    { -- Stuck west side.
      volume = {
        min = Vector(-18.66900062561,-5.1858375072479,-135.72891235352),
        max = Vector(-7.6199998855591,-2.5862901210785,-134.26261901855)
      },
      destination = Vector(-13.203125,-1.7859375476837,-131.109375),
      flag = kStuckFlag.NoSkulkJump
    },

    { -- Stuck east side.
      volume = {
        min = Vector(-18.66900062561,-5.1629424095154,-126.3256072998),
        max = Vector(-7.6199998855591,-2.5016083717346,-125.02695465088)
      },
      destination = Vector(-13.203125,-1.7859375476837,-131.109375),
      flag = kStuckFlag.NoSkulkJump
    },
  },
}

Bishop.debug.FileExit(debug.getinfo(1, "S"))
