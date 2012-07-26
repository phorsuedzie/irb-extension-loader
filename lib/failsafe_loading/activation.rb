require 'failsafe_loading'

module FailsafeLoading

  class Activation

    def self.perform(*args)
      new(*args).perform
    end

    def self.all
      @activations ||= []
    end

    def self.empty?
      all.empty?
    end

    attr_reader :description
    attr_reader :state

    def initialize(description, type, file, initialization, options = {})
      @description =
          case type
          when :library
            "(#{description})"
          when :plugin
            "[#{description}]"
          else
            "?#{description}?"
          end
      @type = type
      @file = file
      @initialization = initialization
      @options = options
      self.class.all.push(self)
    end

    def perform
      @state =
          if @options[:local] && @file && !File.exists?(@file)
            :skip
          else
            load_and_initialize
          end
    end

    private

    def context
      @context ||=
          case @type
          when :plugin
            Module.new do
              extend Evaluator::Plugin
              extend Runner.runner.helpers_module
            end
          when :library
            if @options[:local]
              Module.new do
                extend Evaluator::PluginLibrary
                extend Runner.runner.helpers_module
              end
            else
              Module.new do
                extend Evaluator::Library
                extend Runner.runner.helpers_module
              end
            end
          end
    end

    def file_loading_code(file)
      if @options[:local]
        %|eval(File.read("#{file}"), nil, "#{file}")|
      else
        %|require "#{file}"|
      end
    end

    def load_and_initialize
      file_loading = file_loading_code(@file) if @file
      initialization = @initialization
      error =
          begin
            context.instance_eval do
              file_loading and eval(file_loading)
              initialization and initialization.call
            end
            nil
          rescue LoadError => e
            e
          rescue => e
            e
          end
      if error
        @options[:on_error] and @options[:on_error].call(error)
        LoadError === error ? :load_error : e
      end
    end

  end

end

