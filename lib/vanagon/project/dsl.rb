require 'vanagon/errors'
require 'vanagon/logger'
require 'vanagon/project'
require 'vanagon/utilities'
require 'vanagon/component/source'
require 'git/rev_list'
require 'yaml'

class Vanagon
  class Project
    class DSL
      # Constructor for the DSL object
      #
      # @param name [String] name of the project
      # @param configdir [String] location for 'configs' directory for this project
      # @param platform [Vanagon::Platform] platform for the project to build against
      # @param include_components [List] optional list restricting the loaded components
      # @return [Vanagon::Project::DSL] A DSL object to describe the {Vanagon::Project}
      def initialize(name, configdir, platform, include_components = [])
        @name = name
        @project = Vanagon::Project.new(@name, platform)
        @include_components = include_components.to_set
        @configdir = configdir
      end

      # Primary way of interacting with the DSL
      #
      # @param name [String] name of the project
      # @param block [Proc] DSL definition of the project to call
      def project(name, &)
        yield(self)
      end

      # Accessor for the project.
      #
      # @return [Vanagon::Project] the project the DSL methods will be acting against
      def _project
        @project
      end


      # Project attributes and DSL methods defined below
      #
      #
      # All purpose getter. This object, which is passed to the project block,
      # won't have easy access to the attributes of the @project, so we make a
      # getter for each attribute.
      #
      # We only magically handle get_ methods, any other methods just get the
      # standard method_missing treatment.
      #
      def method_missing(method_name, *args)
        attribute_match = method_name.to_s.match(/get_(.*)/)
        if attribute_match
          attribute = attribute_match.captures.first
          @project.send(attribute)
        elsif @project.settings.key?(method_name)
          return @project.settings[method_name]
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        method_name.to_s.start_with?('get_') || @project.settings.key?(method_name) || super
      end


      # Sets a key value pair on the settings hash of the project
      #
      # @param name [String] name of the setting
      # @param value [String] value of the setting
      def setting(name, value)
        @project.settings[name] = value
      end

      def settings
        @project.settings
      end

      # Sets the description of the project. Mainly for use in packaging.
      #
      # @param descr [String] description of the project
      def description(descr)
        @project.description = descr
      end

      # Resets the name of the project. Is useful for dynamically changing the project name.
      #
      # @param the_name [String] name of the project
      def name(the_name)
        @project.name = the_name
      end

      # Sets the homepage for the project. Mainly for use in packaging.
      #
      # @param page [String] url of homepage of the project
      def homepage(page)
        @project.homepage = page
      end

      # Sets the timeout for the project retry logic
      #
      # @param page [Integer] timeout in seconds
      def timeout(to)
        @project.timeout = to
      end

      # Sets the run time requirements for the project. Mainly for use in packaging.
      #
      # @param req [String] of requirements of the project
      def requires(requirement, version = nil)
        @project.requires << OpenStruct.new(:requirement => requirement, :version => version)
      end

      # Indicates that this component replaces a system level package. Replaces can be collected and used by the project and package.
      #
      # @param replacement [String] a package that is replaced with this component
      # @param version [String] the version of the package that is replaced
      def replaces(replacement, version = nil)
        @project.replaces << OpenStruct.new(:replacement => replacement, :version => version)
      end

      # Indicates that this component provides a system level package. Provides can be collected and used by the project and package.
      #
      # @param provide [String] a package that is provided with this component
      # @param version [String] the version of the package that is provided with this component
      def provides(provide, version = nil)
        @project.provides << OpenStruct.new(:provide => provide, :version => version)
      end

      # Indicates that this component conflicts with another package,
      # so both cannot be installed at the same time. Conflicts can be
      # collected and used by the project and package.
      #
      # @param pkgname [String] name of the package which conflicts with this component
      # @param version [String] the version of the package that conflicts with this component
      def conflicts(pkgname, version = nil)
        @project.conflicts << OpenStruct.new(:pkgname => pkgname, :version => version)
      end

      # Sets the version for the project. Mainly for use in packaging.
      #
      # @param ver [String] version of the project
      def version(ver)
        @project.version = ver
      end

      # Sets the release for the project. Mainly for use in packaging.
      #
      # @param rel [String] release of the project
      def release(rel)
        @project.release = rel
      end

      # Generate source packages in addition to binary packages.
      # Currently only implemented for rpm/deb packages.
      #
      # @param source_artifacts [Boolean] whether or not to output
      #        source packages
      def generate_source_artifacts(source_artifacts)
        @project.source_artifacts = source_artifacts
      end

      # Generate os-specific packaging artifacts (rpm, deb, etc)
      #
      # @param pkg [Boolean] whether or not to output packages
      def generate_packages(pkg)
        @project.generate_packages = pkg
      end

      # Output os-specific archives containing the binary output
      #
      # @param archive [Boolean] whether or not to output archives
      def generate_archives(archive)
        @project.compiled_archive = archive
      end

      # Sets the release for the project to the number of commits since the
      # last tag. Requires that a git tag be present
      # and reachable from the current commit in that repository.
      #
      def release_from_git
        repo_object = Git.open(File.expand_path("..", @configdir))
        last_tag = repo_object.describe('HEAD', { :abbrev => 0 })
        release(repo_object.rev_list("#{last_tag}..HEAD", { :count => true }))
      rescue Git::Error
        VanagonLogger.error "Directory '#{File.expand_path('..', @configdir)}' cannot be versioned by git. Maybe it hasn't been tagged yet?"
      end

      # Sets the version for the project based on a git describe of the
      # directory that holds the configs. Requires that a git tag be present
      # and reachable from the current commit in that repository.
      #
      def version_from_git
        git_version = Git.open(File.expand_path("..", @configdir)).describe('HEAD', tags: true, abbrev: 9)
        version(git_version.split('-').reject(&:empty?).join('.'))
      rescue Git::Error
        VanagonLogger.error "Directory '#{File.expand_path('..', @configdir)}' cannot be versioned by git. Maybe it hasn't been tagged yet?"
      end

      # Get the version string from a git branch name. This will look for a '.'
      # delimited string of numbers of any length and return that as the version.
      # For example, 'maint/1.7.0/fixing-some-bugs' will return '1.7.0' and '4.8.x'
      # will return '4.8'.
      #
      # @return version string parsed from branch name, fails if unable to find version
      def version_from_branch
        branch = Git.open(File.expand_path("..", @configdir)).current_branch
        if branch =~ /(\d+(\.\d+)+)/
          return $1
        else
          fail "Can't find a version in your branch, make sure it matches <number>.<number>, like maint/1.7.0/fixing-some-bugs"
        end
      rescue Git::Error => e
        fail "Something went wrong trying to find your git branch.\n#{e}"
      end

      # Sets the vendor for the project. Used in packaging artifacts.
      #
      # @param vend [String] vendor or author of the project
      def vendor(vend)
        @project.vendor = vend
      end

      # Adds a directory to the list of directories provided by the project, to be included in any packages of the project
      #
      # @param dir [String] directory to add to the project
      # @param mode [String] octal mode to apply to the directory
      # @param owner [String] owner of the directory
      # @param group [String] group of the directory
      def directory(dir, mode: nil, owner: nil, group: nil)
        @project.directories << Vanagon::Common::Pathname.new(dir, mode: mode, owner: owner, group: group)
      end

      # Adds an arbitrary environment variable to the project, which will be passed
      # on to the platform and inherited by any components built on that platform
      def environment(name, value)
        @project.environment[name] = value
      end

      # Add a user to the project
      #
      # @param name [String] name of the user to create
      # @param group [String] group of the user
      # @param shell [String] login shell to set for the user
      # @param is_system [true, false] if the user should be a system user
      # @param homedir [String] home directory for the user
      def user(name, group: nil, shell: nil, is_system: false, homedir: nil)
        @project.user = Vanagon::Common::User.new(name, group, shell, is_system, homedir)
      end

      # Sets the license for the project. Mainly for use in packaging.
      #
      # @param lic [String] the license the project is released under
      def license(lic)
        @project.license = lic
      end

      # Sets the identifier for the project. Mainly for use in OSX packaging.
      #
      # @param ident [String] uses the reverse-domain naming convention
      def identifier(ident)
        @project.identifier = ident
      end

      # Adds a component to the project
      #
      # @param name [String] name of component to add. must be present in configdir/components and named $name.rb currently
      def component(name)
        VanagonLogger.info "Loading #{name}" if @project.settings[:verbose]
        if @include_components.empty? or @include_components.include?(name)
          component = Vanagon::Component.load_component(name, File.join(@configdir, "components"), @project.settings, @project.platform)
          @project.components << component
        end
      end

      # Adds a target repo for the project
      #
      # @param repo [String] name of the target repository to ship to used in laying out the packages on disk
      def target_repo(repo)
        @project.repo = repo
      end

      # Sets the project to be architecture independent, or noarch
      def noarch
        @project.noarch = true
      end

      # Sets up a rewrite rule for component sources for a given protocol
      #
      # @param protocol [String] a supported component source type (Http, Git, ...)
      # @param rule [String, Proc] a rule used to rewrite component source urls
      def register_rewrite_rule(protocol, rule)
        Vanagon::Component::Source::Rewrite.register_rewrite_rule(protocol, rule)
      end

      # Toggle to apply additional cleanup during the build for space constrained systems
      def cleanup_during_build
        @project.cleanup = true
      end

      # This method will write the project's version to a designated file during package creation
      # @param target [String] a full path to the version file for the project
      def write_version_file(target)
        @project.version_file = Vanagon::Common::Pathname.file(target)
      end

      # This method will write the project's settings (per-platform) to the output directory as yaml after building
      def publish_yaml_settings
        @project.yaml_settings = true
      end

      # This method will write the project's bill-of-materials to a designated directory during package creation.
      # @param target [String] a full path to the directory for the bill-of-materials for the project
      def bill_of_materials(target)
        @project.bill_of_materials = Vanagon::Common::Pathname.new(target)
      end

      # Counter for the number of times a project should retry a task
      def retry_count(retry_count)
        @project.retry_count = retry_count
      end

      # Inherit the settings hash from an upstream project
      #
      # @param upstream_project_name [String] The vanagon project to load settings from
      # @param upstream_git_url [String] The git URL for the vanagon project to load settings from
      # @param upstream_git_branch [String] The git branch for the vanagon project to load settings from
      def inherit_settings(upstream_project_name, upstream_git_url, upstream_git_branch)
        @project.load_upstream_settings(upstream_project_name, upstream_git_url, upstream_git_branch)
      end

      # Inherit the settings hash for the current project and platform from a
      # yaml file as generated by `publish_yaml_settings`
      #
      # @param yaml_settings_uri [String] URI (file://... or http://...) to a file containing a yaml representation of vanagon settings
      # @param yaml_settings_sha1_uri [String] URI (file://... or http://...) to a file the sha1sum for the settings file
      def inherit_yaml_settings(yaml_settings_uri, yaml_settings_sha1_uri = nil, metadata_uri: nil)
        @project.load_yaml_settings(yaml_settings_uri, yaml_settings_sha1_uri)
        @project.load_upstream_metadata(metadata_uri) if metadata_uri
      end

      # Set a package override. Will call the platform-specific implementation
      # This will get set in the spec file, deb rules, etc.
      #
      # @param var the string to be included in the build script
      def package_override(var)
        platform = @project.platform
        platform.package_override(self._project, var)
      end

      # Set additional artifacts to fetch from the build
      #
      # @param [String] path to artifact to fetch from builder
      def fetch_artifact(path)
        @project.artifacts_to_fetch << path
      end

      # Set to true to skip packaging steps during the vanagon build
      #
      # @param [Boolean] var whether or not execute packaging steps during build
      def no_packaging(var)
        @project.no_packaging = var
      end

      # Set to sign additional files during buildtime. Only implemented for
      # windows. Can be specified more than once
      #
      # @param [String] file to sign
      def extra_file_to_sign(file)
        @project.extra_files_to_sign << file
      end

      # The hostname to sign additional files on. Only does anything when there
      # are extra files to sign
      #
      # @param [String] hostname of the machine to run the extra file signing on
      def signing_hostname(hostname)
        @project.signing_hostname = hostname
      end

      # The username to log in to the signing_hostname as. Only does anything
      # when there are extra files to sign
      #
      # @param [String] the username to log in to `signing_hostname` as
      def signing_username(username)
        @project.signing_username = username
      end

      # The command to run to sign additional files. The command should assume
      # it will have the file path appended to the end of the command, since
      # files end up in a temp directory.
      #
      # @param [String] the command to sign additional files
      def signing_command(command)
        @project.signing_commands << command
      end

      # When true, run the signing commands locally rather than SSHing to a
      # signing host.
      #
      # @param [Boolean] Whether to use local signing
      def use_local_signing(var)
        @project.use_local_signing = var
      end
    end
  end
end
