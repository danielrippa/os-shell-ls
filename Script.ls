
  do ->

    { stderr } = dependency 'os.shell.IO'
    { type } = dependency 'reflection.Type'
    { lf } = dependency 'unsafe.Constants'
    { name-from-path } = dependency 'os.filesystem.Path'

    WScript

      ..Arguments.Unnamed

        arg = -> ..Item it
        argc = ..Count

      script-filepath = ..ScriptFullName
      script-name = name-from-path ..ScriptName

      exit = (errorlevel = 0) -> ..Quit errorlevel

    fail = (lines, errorlevel = 1) -> type '[ *:String ]' lines ; lines * "#lf" |> stderr ; exit errorlevel

    {
      script-filepath, script-name,
      exit, fail
    }