
  do ->

    { type } = dependency 'reflection.Type'
    { create-shell } = dependency 'os.win32.com.Shell'
    { object-values } = dependency 'unsafe.Object'
    { value-as-string } = dependency 'reflection.Value'

    event-types = success: 0, error: 1, warning: 2, information: 4, audit-success: 8, audit-failure: 16

    shell = create-shell!

    valid-event-type = (event-type) -> event-type in object-values event-types

    invalid-event-type-message = (event-type) -> "Invalid event-type value #{ value-as-string event-type }. Value must be any of #{ value-as-string event-types }"

    log-event = (event-type, message) ->

      throw type-error invalid-event-type-message event-type unless valid-event-type event-type

      type '< String >' message ; shell.LogEvent event-type, message

    event-types

      log-success = -> log-event ..success, it
      log-error =   -> log-event ..error, it
      log-warning = -> log-event ..warning, it

      log-audit-success = -> log-event ..audit-success, it
      log-audit-failure = -> log-event ..autit-failure, it

    {
      event-types, log-event,
      log-success, log-error, log-warning,
      log-audit-success, log-audit-failure
    }