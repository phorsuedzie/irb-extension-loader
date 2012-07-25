module IrbExtender

  class << self

    def base_dir

      @base_dir ||= (
        base_dir = File.expand_path("..", __FILE__).to_s + "/"
        $: << base_dir unless $:.include?(base_dir)
        base_dir
      )
    end

    # specials :=
    #   {
    #     <file basename w/o ext> =>
    #       one of:
    #       - :upcase
    #       - :default # :camel_case
    #       - "ConstAsDefinedByThisFile"
    #       - %w[List OF Const Names Defined By This Source File]
    #       - [:default].concat %w[Additional Const Names Defined By This Source File]
    def setup_autoload(mod, mod_source, specials = {})
      dir = File.expand_path(".", mod_source)[0..-4]
      pattern = "#{dir}/*.rb"
      Dir.glob(pattern).each do |file|
        name = file[(dir.length + 1)..-4]
        require_path = file[base_dir.length..-1]
        consts = Array(specials[name] || :camel_case)
        Array(consts).each do |name_to_const|
          const_symbol =
              case name_to_const
              when String
                name_to_const
              when :upcase
                name.upcase
              else # :camel_case or special mapping :default as member of list of autoloads
                "/#{name}".gsub(%r{[_/](.)}) {$1.upcase}
              end.to_sym

          mod.autoload const_symbol, require_path
        end
      end
    end

    def run(context, &block)
      Extender.run(context, &block)
    end

  end

  setup_autoload(self, __FILE__, "ansi" => :upcase)

end unless defined?(IrbExtender)
