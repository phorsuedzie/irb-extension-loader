require 'failsafe_loading'

module FailsafeLoading

  # collects all methods provided to the plugin context
  module ConditionalOptions
    def self.evaluation_context
      Module.new {extend Runner.helpers_module}
    end

    def self.evaluate_filter(filter)
      if filter.respond_to?(:call)
        filter.call(evaluation_context)
      else
        filter
      end
    end

    def self.allow?(options)
      !options.key?(:only_if) || evaluate_filter(options[:only_if])
    end

    def self.deny?(options)
      evaluate_filter(options[:not_if])
    end

    def skip?(options)
      !ConditionalOptions.allow?(options) || ConditionalOptions.deny?(options)
    end

  end

end
