Config = {}

Config.Target = "OX" -- "QB", "OX"

Config.AllPianos = true -- true = all pianos, false = only pianos specified in Config.PianoLocations. If true, Config.PianoLocations will be used as spawning extra pianos, or for customized distance.

Config.AudioDistance = "20.0"

Config.PropName = {
    "sf_prop_sf_piano_01a",
    -- "prop_otherpiano_01a" (this doesn't exist, i made it up)
}

Config.PianoLocations = {
    { coords = vector4(686.44, 577.82, 129.46, 100.0) },
    { coords = vector4(955.36, 37.09, 70.78, 0.00) }
}