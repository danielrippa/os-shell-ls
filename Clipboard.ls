
  do ->

    { create-window } = dependency 'os.win32.com.HtmlWindow'
    { create-process } = dependency 'os.shell.Process'

    clipboard = -> create-window!clipboard-data

    get-clipboard-text = -> clipboard!get-data 'Text'

    command-line-arguments = -> <[ /c echo ]> ++ it ++ <[ | clip ]>

    set-clipboard-text = -> create-process '%comspec%', command-line-arguments it

    {
      get-clipboard-text,
      set-clipboard-text
    }