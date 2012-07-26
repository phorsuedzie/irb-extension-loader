WORK IN PROGRESS (working but APIs might change)

Failsafe Loading (for IRB and beyond)
=====================================

Unfortunately, errors are not shown when loading `.irbrc`.

`FailsafeLoading` keeps this "ignore errors" behaviour. But if an extension
fails to load, the failure is reported. And loading continues with the next
extension (other than vanilla irb, which silently stops).

The following kinds of extension loading are supported:
  - library: to require a ruby file provided by the system (rubygems, pry, ...)
  - plugin : to require a ruby file from the plugin directory. A simple plugin
    loads a library and configures it. Helpers can be written to support
    a group of plugins to make their decisions (e.g. by examining the IRB
    context, e.g. if this is a Rails console run).


Installation
============

Check out this repository as `~/.irb/extender` (the name is not important). You
can immediately play around with it as follows:

  - start (vanilla) `irb -f`
  - `load 'example/irbrc'`

To activate it for every irb session, create your own `~/.irbrc` based on
the example and change the path to where `init.rb` is located.

The second path to probably change is the
[plugins](https://github.com/phorsuedzie/irb-extension-loader-plugins) directory.

See `example/irbrc` for a more detailed explanation of the directories.


Extensions
==========

Extensions add helpful functionality to irb. Libraries may just be available
to require and need no further initialization, in which case they can just
be required. The irb extension loader just catches all errors which occur
when loading the library:

    library 'rubygems'

The loader will report whether the `require` failed (or an error occured).

The other way is to load your functionality through a plugin which performs
necessary initialization and/or provides the functionality depending on your
irb environment (e.g. the rails application for which `rails console` was
started).

    plugin 'wirble'          # additionaly initializes Wirble
    plugin 'my_web_service'  # which may read authentication credentials
                             # from a file and configure the base resource

A plugin may be provided severaly options:
   :only_if, :not_if         # if the plugin should (not) be activated in
                             # certain environments - takes a boolean value
                             # or a lambda
   :config                   # will be returned to the plugin when it calls
                             # `config`

See the next section for details on how to write a plugin.

Examples:

    library 'rake', :only_if => File.directory?(Dir.pwd + "/tasks")
    plugin_library 'wirble', :config => {:colorize => true}
    plugin  'stdout_rails_log', :only_if => lambda {|helper| helper.rails?}


Here,

    plugin_library 'wirble'

will load (require)

    ~/.irb/plugins/lib/wirble.rb

(the plugins directory being `~/.irb/plugins`)


Plugins
=======

A plugin is a wrapper around your extension code. It should handle different
irb environments (as e.g. being run from different applications).

A plugin is a ruby file, specified with `plugin`, relative to
your current plugins directory. It

- runs in irb's main context
- can require additional
  - libraries (`library <path to require>`)
  - plugin (libraries) (`plugin <path>`)
- can customize the libraries loaded (`library 'file' do ... end`)
- has access to it's config via `config`

A plugin is a few lines of code as follows:

    library 'wirble' do
      Wirble.init
      Wirble.colorize if (config[:colorize] rescue false)
    end

A useful pattern is to load an abstract application extender plugin which
delegates to the appliation specific plugin based on e.g.
`File.basename(Dir.pwd)` or a different application discriminator.

It can even contain the definition of a helpful method.

If your code contains several independent pathes, you can separate
your concerns in different files:

    if defined?(Rails)
      plugin_library 'rails/rails3'
    elsif ENV.key?('RAILS_ENV')
      plugin_library 'rails/legacy_rails'
    end

The `config` method (see the wirble example) provides access to
your plugin config:

    # .irbrc
    FailsafeLoading.run(self) do
      plugin 'wirble', :config => {:colorize => true}
    end

    # plugins/wirble.rb

    config[:colorize]
    # => true


Plugin Helpers
==============

Plugin helpers are loaded before any extension loading is performed.
They are ruby code defining methods the following way:

    def a_helper_method
      # provide some sophisticated help
    end

They are designed to provide helper methods commonly used in plugins.
See `example/plugins/helper/rails.rb` for a simple incarnation.
