local kTeleportClassNames = debug.getupvaluex(TeleportTrigger.OnTriggerEntered, "kTeleportClassNames")
table.insert(kTeleportClassNames, "Prowler")