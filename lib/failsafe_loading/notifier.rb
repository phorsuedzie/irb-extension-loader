require 'failsafe_loading'

module FailsafeLoading

  module Notifier

    def self.configure(config)
      Core.configure(config)
    end

    module Interface

      def quiet?
        Core.quiet?
      end

      def inline(*options, &block)
        Core.inline(*options, &block)
      end

      alias notify_inline inline

      def write(text, *options)
        Core.write(text, *options)
      end

      def notify(text, *options)
        options = options.first
        o = {:color => :gray}
        o = o.merge(options) if options
        write(text, o)
      end

      def warn(failure, options = {})
        if e = options[:error]
          failure += ": #{e.message}"
          failure << "\n  #{e.backtrace.join("\n  ")}" if Core.config[:backtrace]
        end
        o = {:color => :red}
        o = o.merge(options) if options
        write(failure, o)
      end

    end

    include Interface
    extend Interface

    module Core; class << self
      attr_reader :config

      def configure(config)
        @config = {:quiet => config[:quiet], :color => config[:color]}
      end

      def quiet?
        config[:quiet]
      end

      def colored?
        config[:color]
      end

      def inline(options)
        current, @inline = @inline, true
        yield if block_given?
      ensure
        write("\n", options) if options[:block]
        @inline = current
      end

      def out(text, options = {})
        options ||= {}
        text = text.gsub(/^/, "[#{options[:section]}] ") if options[:section]
        if options[:color]
          color = ANSI.const_get(options[:color].to_s.upcase)
          text = "#{color}#{text}#{ANSI::RESET}"
        end
        if @inline
          print text
        else
          puts text
        end
      end

      def write(text, *options)
        quiet? and return
        unless colored?
          unless options.empty?
            options = options.first.dup
            options.delete(:color)
            options = [options]
          end
        end
        out(text, *options)
      end

    end; end

  end

end
