require 'time'

Gem::Specification.new do |gem|
  gem.name    = 'vanagon'
  gem.version = %x(git describe --tags).tr('-', '.').chomp

  gem.summary = 'Multiplatform build, sign, and ship for Puppet projects'
  gem.description = <<-DESCRIPTION
    Vanagon takes a set of project, component, and platform configuration files, to perform
    multiplatform builds that are packaged into rpms, debs, dmgs, etc.
    It has support for calls into Puppet's packaging gem to provide for package signing and
    shipping within the Puppet infrastructure.
  DESCRIPTION
  gem.license = 'Apache-2.0'

  gem.authors  = ['Puppet By Perforce', 'OpenVoxProjec']
  gem.email    = 'voxpupuli@groups.io'
  gem.homepage = 'http://github.com/OpenVoxProject/vanagon'
  gem.required_ruby_version = ['>= 3.2', '< 4']

  gem.add_dependency('docopt', '~> 0.6.1')
  # Handle git repos responsibly
  # - MIT licensed: https://rubygems.org/gems/git
  gem.add_dependency('git', '>= 1.13', '< 4')
  # Parse scp-style triplets like URIs; used for Git source handling.
  # - MIT licensed: https://rubygems.org/gems/build-uri
  gem.add_dependency('build-uri', '~> 1.0')
  # Handle locking hardware resources
  # - ASL v2 licensed: https://rubygems.org/gems/lock_manager
  gem.add_dependency('lock_manager', '~> 0.1.5')
  # Utilities for `ship` and `repo` commands
  # - ASL v2 licensed: https://rubygems.org/gems/packaging
  gem.add_dependency('packaging', '~> 0.122.3')
  gem.add_dependency('psych', '>= 4.0', '< 6')

  gem.require_path = 'lib'
  gem.bindir       = 'bin'
  gem.executables  = %w[vanagon build inspect ship render repo sign
                          build_host_info build_requirements]

  # Ensure the gem is built out of versioned files
  gem.files = Dir['{bin,extras,lib,spec,resources}/**/*', 'README*', 'LICENSE*'] &
              %x(git ls-files -z).split("\0")
end
