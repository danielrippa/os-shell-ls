
  do ->

    { type } = dependency 'reflection.Type'
    { create-process } = dependency 'os.shell.Process'
    { string-as-lines } = dependency 'unsafe.Text'
    { stderr } = dependency 'os.shell.IO'

    is-tool-available = (executable, working-folder) -> (create-process 'where', [ executable ], working-folder).errorlevel isnt 0

    exec-tool = (executable, options = [], working-folder) ->

      available = is-tool-available executable, working-folder

      output-lines = [] ; errorlevel = -1

      if available

        { errorlevel, stdout: output, stderr: error } = create-process "%comspec% /c #executable", options, working-folder

        if errorlevel isnt 0 => stderr executable, error

        output-lines = if output? then string-as-lines output else []

      { available, output-lines, errorlevel }

    {
      is-tool-available,
      exec-tool
    }