module FailsafeLoading

  module Autoload; end

  def Autoload.base_dir
    @base_dir ||= (
      base_dir = File.expand_path("..", __FILE__).to_s + "/"
      $: << base_dir unless $:.include?(base_dir)
      base_dir
    )
  end

  # const_mapping maps the basename of a file to the constants it defines
  #
  # The default for each file is :camelcase
  #
  # Others mapping values are a single item ore an array of
  # - (most likely one) Symbol (:upcase, :camelcase, :default) specifying a conversion rule
  # - a list of strings specifying (additional) constant names
  #
  # Example:
  # {
  #   :ansi => :upcase, # => ANSI
  #
  #   :error => [:default, "ServerError", "ClientError"], # => Error, ServerError, ClientError
  # }
  def Autoload.setup(mod, mod_source, const_mapping = {})
    dir = File.expand_path(".", mod_source)[0..-4]
    pattern = "#{dir}/*.rb"
    Dir.glob(pattern).each do |file|
      name = file[(dir.length + 1)..-4]
      require_path = file[base_dir.length..-1]
      consts = Array(const_mapping[name] || :camelcase)
      Array(consts).each do |name_to_const_conversion|
        const_name =
            case name_to_const_conversion
            when String
              name_to_const
            when :upcase
              name.upcase
            else # :camelcase == :default
              "/#{name}".gsub(%r{[_/](.)}) {$1.upcase}
            end

        mod.autoload const_name.to_sym, require_path
      end
    end
  end

  def self.setup_autoload(mod, mod_source, *const_mapping)
    Autoload.setup(mod, mod_source, *const_mapping)
  end

  setup_autoload(self, __FILE__, "ansi" => :upcase)

  extend Notifier

  def self.run(context, &block)
    Runner.run(context, &block)
  end

end unless defined?(FailsafeLoading)
