module IRB
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
  end

  module Extender
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
      if options[:local] && required
        required = library_file(required)
        File.exists?(required + ".rb") or state = :skip
      end
      unless state
        state = :red
        begin
          if required
            # if options[:local]
            #   @context.instance_eval File.read(required), required
            # else
              @context.instance_eval {require required}
            # end
          end
          yield if block_given?
          state = :green
        rescue => e
          warn "Activating #{description} failed", :error => e
          state = e
        rescue LoadError => e
          warn "Activating #{description} failed", :error => e
          state = :grey
        end
      end
      activation << [description, state]
    end

    def self.activation
      @activation ||= []
    end

    def self.print_summary
      return if activation.empty?
      inline_notify(:block => true) do
        notify "Console extensions: "
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

    def self.plugin(plugin, options = {})
      return if options.key?(:only_if) && !options[:only_if]
      return if options[:not_if]
      file = plugin_file(plugin)
      begin
        @context.instance_eval {require file}
      rescue => e
        warn "Enabling #{plugin} failed", :error => e
        activation << [plugin, e]
      rescue LoadError => e
        warn "Enabling #{plugin} failed", :error => e
        activation << [plugin, :gray]
      end
    end

    def self.extender
      self
    end

    def self.inline_notify(options = {}, &block)
      current, @inline = @inline, true
      yield
    ensure
      puts "" if options[:block]
      @inline = current
    end

    def self.notify(text, options = {})
      write(text, {:color => :gray}.merge(options))
    end

    def self.warn(failure, options = {})
      if e = options[:error]
        failure += ": #{e.message}"
        failure << "\n  #{e.backtrace.join("\n  ")}" if config[:backtrace]
      end
      write(failure, {:color => :red}.merge(options))
    end

    def self.write(text, options = {})
      return if config[:quiet]
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
            define_method(:extender) do
              memory
            end

            define_method(:irb_plugin) do |*args|
              extender.plugin(*args)
            end

            define_method(:irb_activate) do |*args|
              extender.activate(*args)
            end
          end

          enhanced.__send__(:extend, self)
        end

        self
      end.inject(context, self)
    end


    def self.run(context)
      @context = context
      inject_into(context)
      yield self if block_given?
      print_summary unless config[:quiet]
    end

    def self.context
      @context
    end

    def self.config
      @config ||= {
        :color => true,
        :backtrace => false,
        :quiet => false,
        :plugins => File.expand_path("~/.irb/plugins"),
      }
    end

    def self.configure
      yield config
    end
  end
end
