require 'failsafe_loading/evaluator'

module FailsafeLoading
  module Evaluator::Base

    def current_config(type)
      Runner.runner.config[:tasks][type][Runner.runner.current_task(type)]
    end

  end

end
