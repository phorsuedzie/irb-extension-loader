require 'failsafe_loading'

module FailsafeLoading

  module Runner

    extend Notifier
    extend ConditionalOptions

    def self.load_library(specification, options, block)
      return if skip?(options)
      description = options[:description] || specification || "<not specified>"
      file_to_load =
          if options[:local]
            plugin_library_file(specification) if specification
          else
            specification
          end

      Activation.perform(description, :library, file_to_load, block, {
        :local => options[:local],
        :skip_if_local_file_is_missing => options[:local],
        :on_error => lambda {|e|
          Notifier.warn "Activating #{description} failed", :error => e
        },
      })
    end

    def self.print_summary
      return if Activation.empty?
      notify_inline(:block => true) do
        notify "Console extensions:"
        Activation.all.each do |activation|
          color =
              case state = activation.state
              when nil
                :green
              when :skip
                :skip
              when LoadError
                :grey
              end
          text = " #{activation.description}"
          if color
            notify text, :color => color
          else
            warn text
          end
        end
      end
    end

    def self.current_task(type)
      task_stack[type].last
    end

    def self.task_stack
      @plugin_config_stack ||= {:library => [], :plugin => []}
    end

    def self.execute_task(task)
      action, name, options, task_block = task
      task_stack[action] << name
      case action
      when :plugin
        load_plugin(name, options)
      when :library
        load_library(name, options, task_block)
      end
    ensure
      task_stack[action].pop
    end

    def self.load_plugin(plugin, options = {})
      plugin_config = (config[:tasks][:plugin][plugin] ||= {})
      plugin_config[:active] = nil
      return if skip?(options)
      plugin_config[:active] = true
      Activation.perform(plugin, :plugin, plugin_file(plugin), nil, {
        :local => true,
        :on_error => lambda {|e|
          warn "Enabling #{plugin} failed", :error => e
          plugin_config[:active] = false
        },
      })
    end

    def self.helpers_module
      Context::Helpers
    end

    def self.load_helper(file)
      helper = Module.new
      # helpers_module.const_set("Helper#{helper.__id__}", helper)
      helper.class_eval do
        eval(File.read(file), nil, file)
      end
      helper
    end

    def self.load_helpers
      helper_modules = Dir["#{File.join(plugin_dir, "helper")}/*.rb"].inject([]) do |memo, file|
        memo << load_helper(file)
      end

      helper_modules.each do |helper|
        helpers_module.instance_eval do
          include helper
        end
      end

      helper_modules.each do |helper|
        helper.init if helper.respond_to?(:init)
      end
    end

    def self.plugin_dir
      config[:plugins_path]
    end

    def self.plugin_file(spec)
      File.join(plugin_dir, "#{spec}.rb")
    end

    def self.plugin_library_file(spec)
      File.join(plugin_dir, "lib", "#{spec}.rb")
    end

    def self.add_task(type, name, options, block)
      config[:tasks][type][name] = options[:config] || {}
      tasks << [type, name, options, block]
    end

    def self.tasks
      @tasks ||= []
    end

    def self.runner
      self
    end

    def self.register_modules(modules)
      Context::Extensions.instance_eval do
        modules.each do |m|
          include m
        end
      end
    end

    def self.setup(block)
      Module.new do
        extend Evaluator::Initial
        instance_eval(&block)
      end
    end

    def self.run(context, &block)
      @context = context
      load_helpers
      self.setup(block) if block
      Notifier.configure(config)
      while !tasks.empty?
        execute_task(tasks.shift)
      end
      @context.extend Context::Extensions
      Notifier.quiet? or print_summary
      instance_variables.each {|var| instance_variable_set(var, nil)}
    end

    def self.config
      @config ||= {
        :color => true,
        :backtrace => false,
        :quiet => false,
        :plugins_path => File.expand_path("~/.irb/plugins"),
        :tasks => {
          :plugin => {},
          :library => {},
        }
      }
    end
  end
end
