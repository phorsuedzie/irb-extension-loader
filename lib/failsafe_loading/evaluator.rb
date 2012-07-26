require 'failsafe_loading'

module FailsafeLoading

  # An evaluator is a module which provides just the failsafe_loading
  # interface methods and additional helper methods for the (library) plugin
  # to be executed.

  module Evaluator

    FailsafeLoading.setup_autoload(self, __FILE__)

  end

end
