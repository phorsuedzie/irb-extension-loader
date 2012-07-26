require 'failsafe_loading/evaluator'

module FailsafeLoading

  module Evaluator

    module Plugin

      include Base

      def config
        current_config(:plugin)
      end

      def library(name, options = {}, &block)
        Runner.runner.load_library(name, options, block)
      end

      def plugin_library(name, options = {}, &block)
        Runner.runner.load_library(name, {:local => true}.merge(options), block)
      end

      def plugin(name, options = {})
        if options[:config]
          # do not overwrite if config is defined by someone else ... merge instead?
          Runner.runner.config[:tasks][:plugin][name] ||= options[:config]
        end

        # might be protected against "run again"
        Runner.runner.load_plugin(name, options)
      end

      def provide_methods(*modules)
        modules << Module.new {yield} if block_given?
        Runner.runner.register_modules(modules)
      end

    end

  end

end
