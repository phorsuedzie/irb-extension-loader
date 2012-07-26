require 'failsafe_loading'

module FailsafeLoading

  # contexts are modules which are used to collect modules

  module Context
    FailsafeLoading.setup_autoload(self, __FILE__)
  end
end
