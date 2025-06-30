
  do ->

    { fail, exit, script-name: actual-script-name } = dependency 'os.shell.Script'
    { result-or-error, if-then-else } = dependency 'flow.Conditional'
    { map-array-items: map, array-size } = dependency 'unsafe.Array'
    { type } = dependency 'reflection.Type'
    { is-object } = dependency 'unsafe.Object'
    { is-function } = dependency 'unsafe.Function'
    { value-as-string } = dependency 'reflection.Value'
    { kebab-case, camel-case } = dependency 'unsafe.StringCase'
    { object-member-pairs, object-member-names } = dependency 'unsafe.Object'
    { keep-array-items: keep } = dependency 'unsafe.Array'
    { value-type-name } = dependency 'reflection.TypeName'
    { stdout } = dependency 'os.shell.IO'
    { lines-as-string } = dependency 'unsafe.Text'
    { string-starts-with-segment: starts-with } = dependency 'unsafe.String'

    result-as-errorlevel = (result) -> if (typeof result) is 'number' then result else 0

    result-and-error = (success, result = null, error = null) -> { success, result, error }

    success-with = -> result-and-error yes, it
    failure-with = -> result-and-error no,, { message: it }

    # Help Injection

    COMMAND_NOT_RECOGNIZED = 9009

    description-or-hint = (comment, index) -> switch index

        | 0 => comment
        | 1 => "  #comment"

    description-hint = ([ description, hint ]) -> { description, hint }

    function-description-and-hint = -> it |> function-comments |> map _ , description-or-hint |> description-hint

    function-usage = (command-function, command-path) ->

      param-names = function-parameter-names command-function

      usage = param-names |> map _ , -> "[#{ as-option it }]" |> -> [ "Usage: #{ command-path * ' ' } #{ it * ' ' }" ]

      { description, hint } = function-description-and-hint command-function

      options = param-names |> map _ -> "  #{ as-option it }" |> -> return it if (array-size it) is 0 ; [ "Options: " ] ++ it

      usage ++ description ++ hint ++ options

    command-description = ([ command-name, command ]) ->

      description = switch typeof command

        | 'function' => command |> function-description-and-hint |> (.description)
        | 'object'   => '[sub-command...]'

      "  #{ kebab-case command-name } #description"

    subcommands-usage = (command) ->

      command |> object-member-pairs |> keep _ , ([name]) -> name isnt 'help' |> map _ , command-description

    object-usage = (command, command-path) ->

      usage = [ "Usage: #{ command-path * ' ' } <command> [options...]", "" ]

      subcommands = subcommands-usage command

      usage ++ [ "Available commands for #{ command-path * ' ' }:" ] ++ subcommands

    command-usage = (command-path-node, command-path) ->

      switch typeof command-path-node

        | 'function' => function-usage command-path-node, command-path
        | 'object'   => object-usage   command-path-node, command-path

    show-command-usage = (command, command-path) ->

      command-usage command, command-path |> lines-as-string |> stdout ; 0

    is-valid-command-node = (node) -> (is-object node) or (is-function node)

    validate-commands = (command-node, command-path) ->

      unless is-valid-command-node command-node

        return failure-with "Command must be either function or object, but found: #{ value-type-name command-node }"

      if is-object command-node

        for key, value of command-node

          { success } = result = validate-commands value, command-path ++ [ kebab-case key ]

          return result unless success

      success-with command-node

    inject-help-commands = (validation-result, script-name = actual-script-name) ->

      return validation-result unless validation-result.success

      { result: commands } = validation-result

      walk = (node, path) !->

        return if is-function node

        for key, value of node when value is-object value

          walk value, path ++ [ kebab-case key ]

        node.help ?= -> show-command-usage node, path

      walk commands, [ script-name ]

      success-with commands

    #

    is-flag = -> return no if (typeof it) isnt 'string' ; it `starts-with` '--'

    isnt-a-value = -> (it is void) or (is-flag it)

    parse-args = (args) ->

      step = ([ head, next, ...tail ], acc) ->

        return acc if head is void

        next-and-tail = [ next ] ++ tail

        match head

          | is-flag =>

            key = camel-case head.slice 2

            match next

              | isnt-a-value => acc <<< key: yes ; step next-and-tail, acc

              else acc <<< key: next ; step tail, acc

          else step next-and-tail, acc

      #

      step args, {}

    # Command Selection

    fatal-error-message = (command-path, error-message) -> [ "Fatal error in command '#{ command-path * ' ' }'", "  #error-message" ]

    execute-selected-command = ->

      type '{ success:Boolean result:Object|Null error:Object|Null }' it

      unless it.success => fail [ it.error.message ], 9009

      { result: { command-fn, command-args, command-path } } = it

      (-> command-fn.apply null, command-args)

      |> result-or-error |> ({ success, result, error }) ->

        switch success

          | yes => exit result-as-errorlevel result
          | no  => fail (fatal-error-message command-path, error), 1

    is-command-path-segment = (node, arg) -> (is-object node) and not (arg `starts-with` '--')

    find-command-path-node = (node, argv) ->

      command-path = [] ; args = []

      for arg, index in argv

        if is-command-path-segment node, arg

          node-name = camel-case arg

          if node[node-name]?

            node = node[node-name] ; command-path +++ arg
            continue

        args = argv.slice index
        break

      { command-path-node: node, command-path, args }

    select-command = (injection-result, argv) ->

      return injection-result unless injection-result.success

      { result: commands } = injection-result

      { command-path-node, command-path, args } = find-command-path-node commands, argv

      if (array-size argv) > 0
        if (array-size command-path) is 0

          unknown-command = argv.0

          available-commands = commands |> object-member-names |> map _ , kebab-case

          return failure-with do

            * "Unknown command: '#{ argv * ' ' }'"
              ""
              "Available commands are: #{ available-commands * ', ' }"

            |> lines-as-string

      switch typeof command-path-node

        | 'function' =>

          parsed-args = parse-args args ; command-args = command-path-node |> function-parameter-names |> map _ , -> parsed-args[it]

          success-with { command-path, command-fn: command-path-node, command-args }

        | 'object' =>

          suggestions = command-path-node |> object-member-names |> map _ , kebab-case

          failure-with do

            * "Incomplete command: '#{ command-path * ' ' }'"
              "Did you mean one of: #{ suggestions * ', ' }"

            |> lines-as-string

        else

          failure-with "Unknown command: '#{ argv * ' ' }'"

    execute-command = (commands, argv, script-name = actual-script-name, pipeline-interceptor) ->

      type '< Object >' commands ; type '[ *:String ]' argv
      type '< String Undefined >' script-name ; type '< Function Undefined >' pipeline-interceptor

      interceptor = if pipeline-interceptor isnt void then pipeline-interceptor else (-> it)

      commands

        |> validate-commands _ , [script-name]
        |> inject-help-commands _ , script-name
        |> select-command _ , argv
        |> interceptor
        |> execute-selected-command

    {
      execute-command
    }