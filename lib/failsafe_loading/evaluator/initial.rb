require 'failsafe_loading/evaluator'

module FailsafeLoading

  module Evaluator::Initial

    # library 'rubygems'
    # library 'wirble' { Wirble.init }
    # library "ugly/path", :description => "better text"
    # library "rails_console_helper", :only_if => defined?(Rails)
    # library "rails_console_helper", :not_if => defined?(Pry)
    # library false, :description => "explanation of the yielded block" { ... }
    def library(name, options = {}, &block)
      Runner.runner.add_task(:library, name, options, block)
    end

    # plugin_library "apps/some_app"
    def plugin_library(name, options = {}, &block)
      Runner.runner.add_task(:library, name, {:local => true}.merge(options), block)
    end

    def plugin(name, options = {})
      Runner.runner.add_task(:plugin, name, {:local => true}.merge(options), nil)
    end

    def config
      Runner.runner.config
    end

  end

end
