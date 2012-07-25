WORK IN PROGRESS (working but APIs might change)

IRB Extension Loader
====================

Unfortunately, errors are not shown when loading `.irbrc`.

The `IRB::Extender` keeps this "ignore errors" behaviour. But if an extension
fails to load, it will be reported, and it will continue to load the next
extension and not stop as vanilla irb does.

The following kinds of extension loading are supported:
  - activation: simple loading for libraries not needing configuration
    (e.g. rubygems)
  - plugin: advanced loading with configuration or defered library selection


Installation
============

Check out this repository as `~/.irb/extender` (the name is not important). You
can immediately play around with it as follows:

  - start (vanilla) irb
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

    activate 'rubygems'

The loader will report whether the `require` failed (or an error occured).

The other way is to load your functionality through a plugin which performs
necessary initialization and/or provides the functionality depending on your
irb environment (e.g. the rails application for which `rails console` was
started).

    plugin 'wirble'          # additionaly initialized Wirble
    plugin 'my_web_service'  # which may read authentication credentials
                             # from a file and configure the base resource

See next section for details on how to write a plugin.

Both extensions and plugins can be restricted to (not) being loaded, depending
on a boolean value for the options `:only_if` and `:not_if`.

    activate 'rake', :only_if => File.directory?(Dir.pwd + "/tasks")

An extension can be declared as being 'local'. It will then be required
from the plugins' subdirectory `lib`.

Example:

    activate 'funny_lib', :local => true

will load (require)

    ~/.irb/plugins/lib/funny_lib.rb

(the plugins directory being `~/.irb/plugins`)


Plugins
=======

A plugin is a wrapper around your extension code. It should handle different
irb environments (as e.g. being run from different applications).

A plugin is a ruby file, specified with `plugin`, relative to
your current plugins directory. It

- runs in irb's main context
- can activate (see `activate` above)
  - libraries (`irb activate <path to require>`)
  - or self-made code (`irb_activate <path>, :local => true`)
- can customize the libraries loaded (`irb_activate ... do ... end`)
- has access to it's config via `irb_config`
- has access to the common helper methods via `irb_helper`
- can even register more plugins via `irb_plugin`

A plugin is a few lines of code as follows:

    irb_activate 'wirble' do
      Wirble.init
      Wirble.colorize if (config[:wirble][:color] rescue false)
    end

A useful pattern is to load an abstract application extender plugin which
delegates to the appliation specific plugin based on e.g.
`File.basename(Dir.pwd)` or a different application discriminator.

It can even contain the definition of a helpful method.

If your code contains several independent pathes, you can separated
your concerns in different files:

    if defined?(Rails)
      irb_activate 'rails/rails3', :local => true
    elsif ENV.key?('RAILS_ENV')
      irb_activate 'rails/legacy_rails', :local => true
    end

The `irb_config` method (see the wirble example) provides access to
your plugin config:

    # .irbrc
    IRB::Extender.run(self) do |config|
      plugin 'wirble', :config => {:color => true}
    end

    # plugins/wirble.rb

    irb_config[:color]
    # => true

With `irb_plugin` you can even add another (sub-)plugin from within a
plugin, e.g. depending on your enviroment.


Plugin Helper
=============

Plugin helper are loaded before any extension loading is performed.
They are ruby code defining methods the following way:

    irb_helper.instance_eval do
      def a_helper_method
        # provide some sophisticated help
      end
    end

They are designed to provide helper methods commonly used in plugins.
See `example/plugins/helper/rails.rb` for a simple incarnation.
