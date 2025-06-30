
  do ->

    { fail, exit } = dependency 'os.shell.Script'

    inject-help-commands = (commands-object, script-name) ->

      walk = (node, path) ->

        for key, value of node when typeof! value is 'Object'

          walk value, path ++ [ kebab-case key ]

        if typeof! node is 'Object'

          node.help = show-command-usage node, path

      #

      walk commands-object, [ script-name ]

      commands-object

    is-empty-comment = -> (it is '') or (it is void)

    as-option = -> "--#{ kebab-case it }"

    function-usage = (function-node, command-path) ->

      param-names = function-parameter-names function-node

      usage = do ->

        params-usage = param-names |> map-array-items _ , -> "[#{ as-option it }]"

        [ "Usage: #{ command-path * ' ' } #{ params-usage * ' ' }" ]

      [ first-comment, second-comment ] = function-comments function-node

      description = if is-empty-comment first-comment  then [] else [ '', first-comment ]
      hint =        if is-empty-comment second-comment then [] else [ '', "  #second-comment" ]

      options = do ->

        return [] if (array-size param-names) is 0

        params-options = param-names |> map-array-items _ , -> "  #{ as-option it }"

        [ "Options:" ] ++ params-options

      usage ++ description ++ hint ++ options

    object-usage = (object, command-path) ->

      command = command-path * ' '

      usage = [ "Usage: #command <command> [options...]", '' ]

      subcommand-lines = (command-name, command) ->

        description = do ->

          command-description = switch typeof command

            | 'function' =>

              comments = function-comments command

              if (array-size comments) is 0 then '' else comments.0

            else

              '[sub-command...]'

          "  #{ kebab-case command-name } #command-description"

      available-subcommands = do ->

        subcommands = []

        for key, value of object when key isnt 'help'

          subcommands +++ subcommand-lines key, value

        subcommands

      usage ++ [ "Available Commands for '#command':" ] ++ available-subcommands

    generate-usage = (command-path-node, command-path) ->

      switch typeof command-path-node

        | 'function' => function-usage command-path-node, command-path
        | 'object'   => object-usage   command-path-node, command-path

    show-command-usage = (node, command-path) -> generate-usage node, command-path |> (* "#lf") |> stdout ; 0

    is-flag = ->

      return no if (typeof it) isnt 'string'

      it `string-starts-with` '--'

    isnt-a-value = -> (it is void) or (is-flag it)

    parse-args = (args) ->

      step = ([ head, next, ...tail ]) ->

        return {} if head is void

        next-and-tail = [ next ] ++ tail

        match head

          | is-flag =>

            key = camel-case head.slice 2

            match next

              | isnt-a-value => step next-and-tail <<< "#key": yes

              else step tail <<< "#key": next

          else

            step next-and-tail

      step args

    as-command-execution = (command-path, command-fn, command-args, error-lines) ->

      { command-path, command-fn, command-args, error-lines }

    execute-suggestion = (node, command-path) ->

      suggestions = object-member-names node |> map-array-items _ , kebab-case |> (* ', ')

      error-lines: [ "Incomplete command: #{ command-path * ' ' }", "Did you mean one of: #suggestions ?" ]

    execute-command-node = (command-path-node, args, command-path) ->

      parsed-args = parse-args args

      params = command-path-node |> function-parameter-names |> map-array-items _ , -> parsed-args it

      as-command-execution command-path-node, command-path, params

    find-command-path-node = (argv, commands-object) ->

      node = commands-object

      command-path = [] ; args = []

      for arg, index in argv

        node-name = camel-case arg

        switch typeof node

          | 'object' => node[node-name] ; command-path.push arg

          else

            args = argv.slice index
            break

      { command-path-node: node, command-path, args }

    execute-help-command = (commands-object, argv, help-index, script-name) ->

      path-to-help = argv `array-interval` [ 0, help-index ]

      { command-path-node, command-path } = find-command-path-node path-to-help, commands-object

      context-path = [ script-name ] ++ command-path

      switch typeof command-path-node

        | 'object'   => as-command-execution command-path-node.help, [], context-path
        | 'function' => as-command-execution show-command-usage [ command-path-node, context-path ], context-path

        else return error-lines: [ "Cannot show help for invalid command path: '#{ command-path * ' ' }'" ]

    command-execution = (commands-object, script-name) ->

      type '< Object >' commands-object ; type '< String >' script-name

      (argv) ->

        type '[ *:String ]' argv

        help-index = argv `array-item-index` 'help'

        return execute-help-command commands-object, argv, help-index, script-name if help-index?

        { command-path-node, command-path, args } = find-command-path-node argv, commands-object

        switch typeof command-path-node

          | 'function' => execute-command-node command-path-node, args, command-path
          | 'object'   => execute-suggestion command-path-node, command-path

          else error-lines: [ "Unknown command: '#{ argv * ' ' }'" ]

    fatal-error-message = (command-path, error-message) ->

      [ "Fatal error in command '#{ command-path * ' ' }':", "  #message" ]

    result-as-errorlevel = (result) -> if (typeof result) is 'number' then result else 0

    default-handler = ({ command-path, command-fn, command-args, error-lines }) ->

      fail error-lines, 9009 if error-lines?

      try errorlevel = result-as-errorlevel command-fn.apply null, command-args
      catch => fail (fatal-error-message command-path, e.message), 1

      exit errorlevel

    handler-and-command-result = (commands-object, custom-handler) ->

      commands-object |> inject-help-commands script-name

      execution = command-execution commands-object, script-name

      command-result = execution argv

      handler = if custom-handler is void then default-handler else custom-handler

      { handler, command-result }

    execute-command = (commands-object, custom-handler) ->

      type '< Object >' commands-object ; type '< Function Undefined >' custom-handler

      { handler, command-result } = handler-and-command-result commands-object, custom-handler

      handler command-result, default-handler

    {
      command-execution,
      execute-command
    }
