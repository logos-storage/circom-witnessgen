version     = "0.0.2"
author      = "Balazs Komuves"
description = "Witness generation for circom circuits"
license     = "MIT OR Apache-2.0"
srcDir      = "nim"

installExt  = @["nim"]
skipDirs    = @["tmp"]

bin         = @["testMain"]

requires "constantine >= 0.2.0"