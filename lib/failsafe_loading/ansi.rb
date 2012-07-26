require 'failsafe_loading'

module FailsafeLoading

  module ANSI
    RESET     = "\e[0m"
    GRAY      = "\e[0;90m"
    RED       = "\e[31m"
    GREEN     = "\e[32m"
    YELLOW    = "\e[33m"
    BLUE      = "\e[34m"
    MAGENTA   = "\e[35m"
    CYAN      = "\e[36m"
    WHITE     = "\e[37m"

    SKIP      = GRAY
    LOAD_ERROR= GRAY
  end

end
