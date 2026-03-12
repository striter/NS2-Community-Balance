Bishop.debug.FileEntry(debug.getinfo(1, "S"))

kStuckData = {
--------------------------------------------------------------------------------
-- Southern Lava Falls.
--------------------------------------------------------------------------------
  {
    { -- Between crate and ramp.
      volume = {
        min = Vector(-4.5711679458618,-7.8965845108032,41.602085113525),
        max = Vector(-3.1201117038727,-6.6216526031494,43.315235137939)
      },
      destination = Vector(-4,-5.9265623092651,44.9921875),
      flag = kStuckFlag.Jump
    },

    { -- Move past left ladder.
      volume = {
        min = Vector(-5.6825904846191,-8.5752763748169,41.200626373291),
        max = Vector(15.34610748291,-6.5799880027771,43.315238952637)
      },
      destination = Vector(6.5234375,-6.1125001907349,42.8671875),
      flag = kStuckFlag.None
    },

    { -- Jump left catwalk.
      volume = {
        min = Vector(-6.0225281715393,-7.6196608543396,40.957939147949),
        max = Vector(15.443204879761,-6.7346677780151,43.315238952637)
      },
      destination = Vector(6.5078125,-4.7843751907349,45.875),
      flag = kStuckFlag.Jump
    },

    { -- Jump right catwalk.
      volume = {
        min = Vector(-15.815871238708,-8.8443632125854,48.202407836914),
        max = Vector(15.44923210144,-6.8951606750488,51.295780181885)
      },
      destination = Vector(-0.8125,-5.9343748092651,45.3671875),
      flag = kStuckFlag.Jump
    }
  },

--------------------------------------------------------------------------------
-- West Lava Falls.
--------------------------------------------------------------------------------
  {
    { -- Pipe under ramp (west side).
      volume = {
        min = Vector(16.052801132202,-7.1867513656616,24.438974380493),
        max = Vector(21.189392089844,-6.1998820304871,30.5583152771)
      },
      destination = Vector(19.9765625,-5.9499998092651,23.140625),
      flag = kStuckFlag.None
    },

    { -- Pipe under ramp (east side).
      volume = {
        min = Vector(16.333631515503,-7.3854570388794,24.411373138428),
        max = Vector(21.189392089844,-6.2232065200806,37.725467681885)
      },
      destination = Vector(23.0859375,-5.9265623092651,34.5234375),
      flag = kStuckFlag.Jump
    }
  },

--------------------------------------------------------------------------------
-- North Lava Falls.
--------------------------------------------------------------------------------
  {
    { -- Eastern catwalk.
      volume = {
        min = Vector(31.699197769165,-7.9074215888977,48.333362579346),
        max = Vector(48.394309997559,-6.5885210037231,50.112277984619)
      },
      destination = Vector(38.8828125,-5.9265623092651,46.515625),
      flag = kStuckFlag.Jump
    },

    { -- Western catwalk, under container.
      volume = {
        min = Vector(36.142959594727,-8.2926616668701,41.973697662354),
        max = Vector(40.904682159424,-6.5507917404175,43.416091918945)
      },
      destination = Vector(33.9453125,-7.2937498092651,42.8671875),
      flag = kStuckFlag.None
    },

    { -- Western catwalk south side.
      volume = {
        min = Vector(31.699199676514,-7.9598226547241,41.7493019104),
        max = Vector(37.255336761475,-6.567193031311,43.416095733643)
      },
      destination = Vector(34.3359375,-5.9265623092651,45.6015625),
      flag = kStuckFlag.Jump
    },

    { -- Western catwalk north side.
      volume = {
        min = Vector(40.71586227417,-8.8968648910522,39.355533599854),
        max = Vector(48.394313812256,-6.5640940666199,43.416091918945)
      },
      destination = Vector(43.40625,-5.9343748092651,45.6640625),
      flag = kStuckFlag.Jump
    },
  },
}

Bishop.debug.FileExit(debug.getinfo(1, "S"))
