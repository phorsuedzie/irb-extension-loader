require 'irb_extender'

module IrbExtender
  module Notifications

    class << self

      attr_reader :config

      def configure(config)
        @config = {:quiet => config[:quiet], :color => config[:color]}
      end

      def inline_notify(options)
        current, @inline = @inline, true
        yield
      ensure
        puts "" if options[:block]
        @inline = current
      end

      def write(text, options = nil)
        config[:quiet] and return
        options ||= {}
        text = text.gsub(/^/, "[#{options[:section]}] ") if options[:section]
        if options[:color] && config[:color]
          color = ANSI.const_get(options[:color].to_s.upcase)
          text = "#{color}#{text}#{ANSI::RESET}"
        end
        if @inline
          print text
        else
          puts text
        end
      end

    end

    def inline_notify(options = {}, &block)
      Notifications.inline_notify(options, &block)
    end

    def notify(text, options = nil)
      o = {:color => :gray}
      o = o.merge(options) if options
      write(text, o)
    end

    def warn(failure, options = nil)
      if e = options[:error]
        failure += ": #{e.message}"
        failure << "\n  #{e.backtrace.join("\n  ")}" if config[:backtrace]
      end
      o = {:color => :red}
      o = o.merge(options) if options
      write(failure, o)
    end

    def write(text, options = nil)
      Notifications.write(text, options)
    end

  end

  module Extender
    extend Notifications
    #
    # activate 'rubygems'
    # activate 'wirble' { Wirble.init }
    # activate "apps/some_app", :local => true
    # activate "ugly/path", :description => "better text"
    # activate "rails_console_helper", :only_if => defined?(Rails)
    # activate "rails_console_helper", :not_if => defined?(Pry)
    # activate false, :description => "of the yielded block" do ...; end
    #
    def self.activate(specification, options = {})
      return if options.key?(:only_if) && !options[:only_if]
      return if options[:not_if]
      description = options[:description] || specification || "<not specified>"
      required = specification
      activation_state = [description, :unknown]
      activation << activation_state
      if options[:local] && required
        required = library_file(required)
        File.exists?(required + ".rb") or state = :skip
      end
      unless state
        state = :red
        begin
          if required
            @context.instance_eval {require required}
          end
          yield if block_given?
          state = :green
        rescue => e
          warn "Activating #{description} failed", :error => e
          state = e
        rescue LoadError => e
          warn "Activating #{description} failed", :error => e
          state = :gray
        end
      end
      activation_state.pop; activation_state << state
    end

    def self.activation
      @activation ||= []
    end

    def self.print_summary
      return if activation.empty?
      inline_notify(:block => true) do
        notify "Console extensions:"
        activation.each do |(name, state)|
          text = " #{name}"
          case state
          when Symbol
            notify text, :color => state
          else
            warn text
          end
        end
      end
    end

    def self.plugin_config_stack
      @plugin_config_stack ||= [{}]
    end

    def self.plugin_config
      plugin_config_stack.last
    end

    def self.with_plugin_config(plugin_config)
      plugin_config_stack << plugin_config
      yield
      plugin_config_stack.pop
    end

    def self.plugin(plugin, options = {}, &block)
      plugin_config = config[:extensions][plugin.to_sym]
      unless plugin_config
        plugin_config = {}
        config[:extensions][plugin.to_sym] = plugin_config
      end
      plugin_config[:active] = nil
      return if options.key?(:only_if) && !options[:only_if]
      return if options[:not_if]
      plugin_config[:extender] = config
      plugin_config[:active] = true
      with_plugin_config(plugin_config) do
        file = plugin_file(plugin)
        begin
          @context.instance_eval {
            require file
          }
          @context.instance_eval(&block) if block
        rescue => e
          warn "Enabling #{plugin} failed", :error => e
          activation << [plugin, e]
          config[:active] = false
        rescue LoadError => e
          warn "Enabling #{plugin} failed", :error => e
          activation << [plugin, :gray]
          config[:active] = false
        end
      end
    end

    def self.helper
      @helper ||= Module.new
    end

    def self.load_helper
      Dir["#{plugin_file("helper")}/*.rb"].each do |file|
        helper.instance_eval {
          # Sorry - does not switch context as intended
          require file
        }
      end
    end

    def self.plugin_file(spec)
      File.join(config[:plugins], spec)
    end

    def self.library_file(spec)
      File.join(config[:plugins], "lib", spec)
    end

    def self.plugin_master_file
      config[:plugins]
    end

    def self.inject_into(context)
      Module.new do
        def self.inject(enhanced, injected)
          memory = injected

          class_eval do
            define_method(:irb_extender) do
              memory
            end
          end

          enhanced.__send__(:extend, self)
        end

        def irb_plugin(*args, &block)
          irb_extender.plugin(*args, &block)
        end

        def irb_activate(*args, &block)
          irb_extender.activate(*args, &block)
        end

        def irb_helper
          irb_extender.helper
        end

        def irb_config
          irb_extender.plugin_config
        end

        self
      end.inject(context, self)
    end

    def self.tasks
      @tasks ||= []
    end

    module Collector
      def self.activate(*args, &block)
        Extender.tasks << [:activate, block, *args]
      end

      def self.plugin(name, options = {})
        plugin_config = options[:config] || {}
        Extender.config[:extensions][name.to_sym] = plugin_config
        Extender.tasks << [:plugin, nil, name, options]
      end

      def self.config
        Extender.config
      end
    end

    def self.run(context, &block)
      @context = context
      inject_into(context)
      if block
        Collector.instance_eval(&block)
        Notifications.configure(config)
        load_helper
        tasks.each do |action, block, *args|
          if block
            __send__(action, *args, &block)
          else
            __send__(action, *args)
          end
        end
      end
      print_summary unless config[:quiet]
      instance_variables.each {|var| instance_variable_set(var, nil)}
    end

    def self.config
      @config ||= {
        :color => true,
        :backtrace => false,
        :quiet => false,
        :plugins => File.expand_path("~/.irb/plugins"),
        :extensions => {},
      }
    end
  end
end
