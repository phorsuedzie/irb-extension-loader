require 'failsafe_loading/evaluator'

module FailsafeLoading::Evaluator

  module Library
    def config
      current_config(:library)
    end
  end
end
