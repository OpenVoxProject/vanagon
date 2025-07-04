require 'vanagon/project'
require 'vanagon/driver'
require 'vanagon/errors'
require 'fakefs/spec_helpers'

describe 'Vanagon::Project' do
  let(:component) { double(Vanagon::Component) }
  let(:configdir) { '/a/b/c' }
  let(:platform) do
    OpenStruct.new(:settings => {})
  end
  let(:upstream_platform) do
    OpenStruct.new(:settings => {})
  end

  let(:project_block) do
    "project 'test-fixture' do |proj|
    proj.component 'some-component'
    end"
  end

  let(:upstream_project_block) do
    "project 'upstream-test' do |proj|
    proj.setting(:test, 'upstream-test')
    end"
  end

  let(:inheriting_project_block) do
    "project 'inheritance-test' do |proj|
    proj.inherit_settings 'upstream-test', 'git://some.url', 'master'
    end"
  end

  let(:inheriting_project_block_with_settings) do
    "project 'inheritance-test' do |proj|
    proj.setting(:merged, 'yup')
    proj.inherit_settings 'upstream-test', 'git://some.url', 'master'
    end"
  end

  let(:preset_inheriting_project_block) do
    "project 'inheritance-test' do |proj|
    proj.setting(:test, 'inheritance-test')
    proj.inherit_settings 'upstream-test', 'git://some.url', 'master'
    end"
  end

  let(:postset_inheriting_project_block) do
    "project 'inheritance-test' do |proj|
    proj.inherit_settings 'upstream-test', 'git://some.url', 'master'
    proj.setting(:test, 'inheritance-test')
    end"
  end

  let (:dummy_platform_settings) do
    plat = Vanagon::Platform::DSL.new('debian-6-i386')
    plat.instance_eval <<-END_EVAL, __FILE__, __LINE__ + 1
      platform 'debian-6-i386' do |plat|
        plat.servicetype 'sysv'
        plat.servicedir '/etc/init.d'
        plat.defaultdir '/etc/default'
        settings[:platform_test] = 'debian'
      end
    END_EVAL
    plat._platform
  end


  describe '#vendor=' do
    dummy_platform = Vanagon::Platform.new('el-7-x86_64')
    good_vendor = 'Puppet Inc. <release@puppet.com>'
    bad_vendor = 'Puppet Inc.'

    it 'fails if vendor field does not include email address' do
      project = Vanagon::Project.new('vendor-test', dummy_platform)
      expect { project.vendor = bad_vendor }
        .to raise_error(Vanagon::Error, /Project vendor field must include email address/)
    end

    it 'sets project vendor to the supplied value' do
      project = Vanagon::Project.new('vendor-test', dummy_platform)
      project.vendor = good_vendor
      expect(project.vendor).to eq(good_vendor)
    end
  end

  describe '#vendor_name_only' do
    it 'returns just the name of the vendor' do
      project = Vanagon::Project.new('vendor-test', Vanagon::Platform.new('el-7-x86_64'))
      project.vendor = 'Puppet Inc. <release@puppet.com>'
      expect(project.vendor_name_only).to eq('Puppet Inc.')
    end
  end

  describe '#vendor_email_only' do
    it 'returns just the email address of the vendor' do
      project = Vanagon::Project.new('vendor-test', Vanagon::Platform.new('el-7-x86_64'))
      project.vendor = 'Puppet Inc. <release@puppet.com>'
      expect(project.vendor_email_only).to eq('release@puppet.com')
    end
  end

  describe '#get_root_directories' do
    before do
      allow_any_instance_of(Vanagon::Project::DSL).to receive(:puts)
      allow(Vanagon::Driver).to receive(:configdir).and_return(configdir)
      allow(Vanagon::Component).to receive(:load_component).with('some-component', any_args).and_return(component)
    end

    let(:test_sets) do
      [
        {
          :directories => ["/opt/puppetlabs/bin", "/etc/puppetlabs", "/var/log/puppetlabs",
                           "/etc/puppetlabs/puppet", "/opt/puppetlabs"],
          :results => ["/opt/puppetlabs", "/etc/puppetlabs", "/var/log/puppetlabs"],
        },
        {
          :directories => ["/opt/puppetlabs/bin", "/etc/puppetlabs", "/var/log/puppetlabs",
                           "/etc/puppetlabs/puppet", "/opt/puppetlabs/lib"],
          :results => ["/opt/puppetlabs/bin", "/etc/puppetlabs", "/var/log/puppetlabs",
                       "/opt/puppetlabs/lib"],
        },
      ]
    end

    it 'returns only the highest level directories' do
      test_sets.each do |set|
        allow(component).to receive(:directories).and_return([])
        proj = Vanagon::Project::DSL.new('test-fixture', configdir, platform, [])
        proj.instance_eval(project_block)
        set[:directories].each { |dir| proj.directory dir }
        expect(proj._project.get_root_directories.sort).to eq(set[:results].sort)
      end
    end
  end

  describe "#load_upstream_settings" do
    before(:each) do
      # stub out all of the git methods so we don't actually clone
      allow(Vanagon::Component::Source::Git)
        .to receive(:valid_remote?)
        .with(Build::URI.parse('git://some.url'))
        .and_return(true)
      git_source = Vanagon::Component::Source::Git.new('git://some.url', workdir: Dir.getwd)
      allow(Vanagon::Component::Source::Git).to receive(:new).and_return(git_source)
      allow(git_source).to receive(:fetch).and_return(true)

      # stubs for the upstream project
      upstream_proj = Vanagon::Project::DSL.new('upstream-test', configdir, upstream_platform, [])
      upstream_proj.instance_eval(upstream_project_block)
      allow(Vanagon::Project).to receive(:load_project).and_return(upstream_proj._project)
      allow(Vanagon::Platform).to receive(:load_platform).and_return(upstream_platform)

      class Vanagon
        class Project
          BUILD_TIME = '2017-07-10T13:34:25-07:00'
          VANAGON_VERSION = '0.0.0-rspec'
        end
      end

    end

    it 'loads upstream settings' do
      inheriting_proj = Vanagon::Project::DSL.new('inheritance-test', configdir, platform, [])
      inheriting_proj.instance_eval(inheriting_project_block)
      expect(inheriting_proj._project.settings[:test]).to eq('upstream-test')
    end

    it 'overrides duplicate settings from before the load' do
      inheriting_proj = Vanagon::Project::DSL.new('inheritance-test', configdir, platform, [])
      inheriting_proj.instance_eval(preset_inheriting_project_block)
      expect(inheriting_proj._project.settings[:test]).to eq('upstream-test')
    end

    it 'lets you override settings after the load' do
      inheriting_proj = Vanagon::Project::DSL.new('inheritance-test', configdir, platform, [])
      inheriting_proj.instance_eval(postset_inheriting_project_block)
      expect(inheriting_proj._project.settings[:test]).to eq('inheritance-test')
    end

    it 'merges settings' do
      inheriting_proj = Vanagon::Project::DSL.new('inheritance-test', configdir, platform, [])
      inheriting_proj.instance_eval(inheriting_project_block_with_settings)
      expect(inheriting_proj._project.settings[:test]).to eq('upstream-test')
      expect(inheriting_proj._project.settings[:merged]).to eq('yup')
    end
  end

  describe 'platform settings' do
    before do
      allow(Vanagon::Component)
        .to receive(:load_component)
        .with('some-component', any_args)
        .and_return(component)
    end

    it 'loads settings set in platforms' do
      settings_proj = Vanagon::Project::DSL.new(
        'settings-test', configdir, dummy_platform_settings, []
      )
      settings_proj.instance_eval(project_block)
      expect(settings_proj._project.settings[:platform_test]).to eq('debian')
    end
  end

  describe "#load_yaml_settings" do
    subject(:project) do
      project = Vanagon::Project.new('yaml-inheritance-test', Vanagon::Platform.new('aix-7.2-ppc'))
      project.settings = { merged: 'nope', original: 'original' }
      project
    end

    let(:yaml_filename) { 'settings.yaml' }
    let(:sha1_filename) { "#{yaml_filename}.sha1" }

    let(:yaml_path) { "/path/to/#{yaml_filename}" }
    let(:sha1_path) { "/path/to/#{sha1_filename}" }

    let(:yaml_content) { { other: 'other', merged: 'yup' }.to_yaml }

    let(:local_yaml_uri) { "file://#{yaml_path}" }
    let(:http_yaml_uri) { "http:/#{yaml_path}" }

    before(:each) do
      allow(Dir).to receive(:mktmpdir) { |&block| block.yield '' }
    end

    it "fails for a local source if the settings file doesn't exist" do
      expect { project.load_yaml_settings(local_yaml_uri) }.to raise_error(Vanagon::Error)
    end

    it "fails if given a git source" do
      expect { project.load_yaml_settings('git://some/repo.uri') }.to raise_error(Vanagon::Error)
    end

    it "fails when given an unknown source" do
      expect { project.load_yaml_settings("fake://source.uri") }.to raise_error(Vanagon::Error)
    end

    it "fails if downloading over HTTP without a valid sha1sum URI" do
      allow(Vanagon::Component::Source::Http)
        .to receive(:valid_url?)
        .with(http_yaml_uri)
        .and_return(true)
      http_source = instance_double(Vanagon::Component::Source::Http)
      allow(Vanagon::Component::Source).to receive(:source).and_return(http_source)
      allow(http_source).to receive(:verify).and_return(true)

      expect { project.load_yaml_settings(http_yaml_uri) }.to raise_error(Vanagon::Error)
    end

    context "with a valid source" do
      before(:each) do
        local_source = instance_double(Vanagon::Component::Source::Local)
        allow(local_source).to receive(:fetch)
        allow(local_source).to receive(:verify).and_return(true)
        allow(local_source).to receive(:file).and_return(yaml_path)

        allow(Vanagon::Component::Source).to receive(:determine_source_type).and_return(:local)
        allow(Vanagon::Component::Source).to receive(:source).and_return(local_source)
        allow(YAML).to receive(:safe_load_file).with(yaml_path, permitted_classes: [Symbol]).and_return({ other: 'other', merged: 'yup' })

        expect { project.load_yaml_settings(local_yaml_uri) }.not_to raise_exception
      end

      it "overwrites the current project's settings when they conflict" do
        expect(project.settings[:merged]).to eq('yup')
      end

      it "adopts new settings found in the other project" do
        expect(project.settings[:other]).to eq('other')
      end

      it "keeps its own settings when there are no conflicts" do
        expect(project.settings[:original]).to eq('original')
      end
    end
  end

  describe "#filter_component" do
    # All of the following tests should be run with one project level
    # component that isn't included in the build_deps of another component
    before(:each) do
      @proj = Vanagon::Project.new('test-fixture-with-comps', platform)
      @not_included_comp = Vanagon::Component.new('test-fixture-not-included', {}, {})
      @proj.components << @not_included_comp
    end

    it "returns nil when given a component that doesn't exist" do
      expect(@proj.filter_component("fake")).to eq([])
    end

    it "returns only the component with no build deps" do
      comp = Vanagon::Component.new('test-fixture1', {}, {})
      @proj.components << comp
      expect(@proj.filter_component(comp.name)).to eq([comp])
    end

    it "returns component and one build dep" do
      comp1 = Vanagon::Component.new('test-fixture1', {}, {})
      comp2 = Vanagon::Component.new('test-fixture2', {}, {})
      comp1.build_requires << comp2.name
      @proj.components << comp1
      @proj.components << comp2
      expect(@proj.filter_component(comp1.name)).to eq([comp1, comp2])
    end

    it "returns only the component with build deps that are not components of the @project" do
      comp = Vanagon::Component.new('test-fixture1', {}, {})
      comp.build_requires << "fake-name"
      @proj.components << comp
      expect(@proj.filter_component(comp.name)).to eq([comp])
    end

    it "returns the component and build deps with both @project components and external build deps" do
      comp1 = Vanagon::Component.new('test-fixture1', {}, {})
      comp2 = Vanagon::Component.new('test-fixture2', {}, {})
      comp1.build_requires << comp2.name
      comp1.build_requires << "fake-name"
      @proj.components << comp1
      @proj.components << comp2
      expect(@proj.filter_component(comp1.name)).to eq([comp1, comp2])
    end

    it "returns the component and multiple build deps" do
      comp1 = Vanagon::Component.new('test-fixture1', {}, {})
      comp2 = Vanagon::Component.new('test-fixture2', {}, {})
      comp3 = Vanagon::Component.new('test-fixture3', {}, {})
      comp1.build_requires << comp2.name
      comp1.build_requires << comp3.name
      @proj.components << comp1
      @proj.components << comp2
      @proj.components << comp3
      expect(@proj.filter_component(comp1.name)).to eq([comp1, comp2, comp3])
    end

    it "returns the component and multiple build deps with external build deps" do
      comp1 = Vanagon::Component.new('test-fixture1', {}, {})
      comp2 = Vanagon::Component.new('test-fixture2', {}, {})
      comp3 = Vanagon::Component.new('test-fixture3', {}, {})
      comp1.build_requires << comp2.name
      comp1.build_requires << comp3.name
      comp1.build_requires << "another-fake-name"
      @proj.components << comp1
      @proj.components << comp2
      @proj.components << comp3
      expect(@proj.filter_component(comp1.name)).to eq([comp1, comp2, comp3])
    end
  end

  describe '#get_preinstall_actions' do
    it "Collects the preinstall actions for the specified package state" do
      proj = Vanagon::Project.new('action-test', platform)
      proj.get_preinstall_actions('upgrade')
      proj.get_preinstall_actions('install')
      expect(proj.get_preinstall_actions('install')).to be_instance_of(String)
    end
  end

  describe '#get_trigger_scripts' do
    it "Collects the install triggers for the project for the specified packing state" do
      proj = Vanagon::Project.new('action-test', platform)
      expect(proj.get_trigger_scripts('install')).to eq({})
      expect(proj.get_trigger_scripts('upgrade')).to be_instance_of(Hash)
    end
    it 'fails with empty install trigger action' do
      proj = Vanagon::Project.new('action-test', platform)
      expect { proj.get_trigger_scripts([]) }.to raise_error(Vanagon::Error)
    end
    it 'fails with incorrect install trigger action' do
      proj = Vanagon::Project.new('action-test', platform)
      expect { proj.get_trigger_scripts('foo') }.to raise_error(Vanagon::Error)
    end
  end

  describe '#get_interest_triggers' do
    it "Collects the interest triggers for the project for the specified packaging state" do
      proj = Vanagon::Project.new('action-test', platform)
      expect(proj.get_interest_triggers('install')).to eq([])
      expect(proj.get_interest_triggers('upgrade')).to be_instance_of(Array)
    end
    it 'fails with empty interest trigger action' do
      proj = Vanagon::Project.new('action-test', platform)
      expect { proj.get_interest_triggers([]) }.to raise_error(Vanagon::Error)
    end
    it 'fails with incorrect interest trigger action' do
      proj = Vanagon::Project.new('action-test', platform)
      expect { proj.get_interest_triggers('foo') }.to raise_error(Vanagon::Error)
    end
  end

  describe '#get_activate_triggers' do
    it "Collects the activate triggers for the project for the specified packaging state" do
      proj = Vanagon::Project.new('action-test', platform)
      expect(proj.get_activate_triggers()).to be_instance_of(Array)
      expect(proj.get_activate_triggers()).to be_instance_of(Array)
    end
  end

  describe '#generate_dependencies_info' do
    before(:each) do
      @proj = Vanagon::Project.new('test-project', platform)
    end

    it "returns a hash of components and their versions" do
      comp1 = Vanagon::Component.new('test-component1', {}, {})
      comp1.version = '1.0.0'
      comp2 = Vanagon::Component.new('test-component2', {}, {})
      comp2.version = '2.0.0'
      comp2.options[:ref] = '123abcd'
      comp3 = Vanagon::Component.new('test-component3', {}, {})
      @proj.components << comp1
      @proj.components << comp2
      @proj.components << comp3

      expect(@proj.generate_dependencies_info()).to eq({
        'test-component1' => { 'version' => '1.0.0' },
        'test-component2' => { 'version' => '2.0.0', 'ref' => '123abcd' },
        'test-component3' => {},
      })
    end
  end

  describe '#build_manifest_json' do
    before(:each) do
      class Vanagon
        class Project
          BUILD_TIME = '2017-07-10T13:34:25-07:00'
          VANAGON_VERSION = '0.0.0-rspec'
        end
      end

      @proj = Vanagon::Project.new('test-project', platform)
    end

    it 'generates a hash with the expected build metadata' do
      comp1 = Vanagon::Component.new('test-component1', {}, {})
      comp1.version = '1.0.0'
      @proj.components << comp1
      @proj.version = '123abcde'

      expect(@proj.build_manifest_json()).to eq({
        'packaging_type' => { 'vanagon' => '0.0.0-rspec' },
        'version' => '123abcde',
        'components' => { 'test-component1' => { 'version' => '1.0.0' } },
        'build_time' => '2017-07-10T13:34:25-07:00',
      })
    end

    it 'calls pretty-print when we want pretty json' do
      comp1 = Vanagon::Component.new('test-component1', {}, {})
      comp1.version = '1.0.0'
      @proj.components << comp1
      @proj.version = '123abcde'

      expect(JSON).to receive(:pretty_generate)
      @proj.build_manifest_json(true)
    end
  end

  describe '#save_manifest_json' do
    include FakeFS::SpecHelpers
    let(:platform_name) { 'el-7-x86_64' }
    let(:platform) { Vanagon::Platform.new(platform_name) }

    before(:each) do
      class Vanagon
        class Project
          BUILD_TIME = '2018-07-10T13:34:25-07:00'
          VANAGON_VERSION = '0.0.0-rspec'
        end
      end

      @proj = Vanagon::Project.new('test-project', platform)
    end

    it 'generates a file with the expected build metadata' do
      correct_sample_metadata = {
        'packaging_type' => { 'vanagon' => '0.0.0-rspec' },
        'version' => '123abcde',
        'components' => { 'test-component-10' => { 'version' => '1.2.3' } },
        'build_time' => '2018-07-10T13:34:25-07:00',
      }
      bad_sample_metadata = {
        'BAD KEY' => 'BAD VALUE'
      }
      comp1 = Vanagon::Component.new('test-component-10', {}, {})
      comp1.version = '1.2.3'
      @proj.components << comp1
      @proj.version = '123abcde'
      FakeFS do
        @proj.save_manifest_json(platform)

        old_style_metadata = JSON.parse(File.read('ext/build_metadata.json'))
        expect(old_style_metadata).to eq(correct_sample_metadata)

        metadata_with_project_and_platform = JSON.parse(
          File.read("ext/build_metadata.test-project.#{platform_name}.json"))
        expect(metadata_with_project_and_platform).to eq(correct_sample_metadata)
        expect(metadata_with_project_and_platform).not_to eq(bad_sample_metadata)
      end
    end
  end


  describe '#publish_yaml_settings' do
    subject(:project) do
      project = Vanagon::Project.new('test-project', platform)
      project.settings = { key: 'value' }
      project.version = 'version'
      project.yaml_settings = true
      project
    end

    let(:platform_name) { 'aix-7.2-ppc' }
    let(:platform) { Vanagon::Platform.new(platform_name) }


    let(:yaml_output_path) do
      File.expand_path("test-project-version.#{platform_name}.settings.yaml", "output")
    end
    let(:sha1_output_path) do
      File.expand_path("test-project-version.#{platform_name}.settings.yaml.sha1", "output")
    end

    let(:yaml_file) { double('yaml_file') }
    let(:sha1_file) { double('sha1_file') }

    let(:sha1_content) { 'abcdef' }
    let(:sha1_object) { instance_double(Digest::SHA1, hexdigest: sha1_content) }

    it 'writes project settings as yaml and a sha1sum for the settings to the output directory' do
      allow(File).to receive(:open).with(yaml_output_path, "w").and_yield(yaml_file)
      allow(Digest::SHA1).to receive(:file).with(yaml_output_path).and_return(sha1_object)
      allow(File).to receive(:open).with(sha1_output_path, "w").and_yield(sha1_file)
      expect(yaml_file).to receive(:write).with({ key: 'value' }.to_yaml)
      expect(sha1_file).to receive(:puts).with(sha1_content)
      expect { project.publish_yaml_settings(platform) }.not_to raise_error
    end

    it 'does not write yaml settings or a sha1sum unless told to' do
      project.yaml_settings = false
      expect(File).not_to receive(:open)
      expect { project.publish_yaml_settings(platform) }.not_to raise_error
    end

    it "fails if the output directory doesn't exist" do
      allow_any_instance_of(File).to receive(:open).with(yaml_output_path).and_raise(Errno::ENOENT)
      allow_any_instance_of(File).to receive(:open).with(sha1_output_path).and_raise(Errno::ENOENT)
      expect { project.publish_yaml_settings(platform) }.to raise_error(Errno::ENOENT)
    end

    it "fails unless the project has a version" do
      project.version = nil
      expect { project.publish_yaml_settings(platform) }.to raise_error(Vanagon::Error)
    end
  end

  describe '#generate_package' do
    it "builds packages by default" do
      platform = Vanagon::Platform::DSL.new('el-7-x86_64')
      platform.instance_eval("platform 'el-7-x86_6' do |plat| end", __FILE__, __LINE__)
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, platform._platform, [])
      allow(platform._platform).to receive(:generate_package).and_return(["# making a package"])
      expect(proj._project.generate_package).to eq(["# making a package"])
    end

    it "builds packages and archives if configured for both" do
      platform = Vanagon::Platform::DSL.new('el-7-x86_64')
      platform.instance_eval("platform 'el-7-x86_6' do |plat| end", __FILE__, __LINE__)
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, platform._platform, [])
      proj.generate_archives(true)
      allow(platform._platform).to receive(:generate_package).and_return(["# making a package"])
      allow(platform._platform)
        .to receive(:generate_compiled_archive)
        .and_return(["# making an archive"])
      expect(proj._project.generate_package).to eq(["# making a package", "# making an archive"])
    end

    it "can build only archives" do
      platform = Vanagon::Platform::DSL.new('el-7-x86_64')
      platform.instance_eval("platform 'el-7-x86_6' do |plat| end", __FILE__, __LINE__)
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, platform._platform, [])
      proj.generate_archives(true)
      proj.generate_packages(false)
      allow(platform._platform)
        .to receive(:generate_compiled_archive)
        .and_return(["# making an archive"])
      expect(proj._project.generate_package).to eq(["# making an archive"])
    end

    it "builds nothing if that's what you really want" do
      platform = Vanagon::Platform::DSL.new('el-7-x86_64')
      platform.instance_eval("platform 'el-7-x86_6' do |plat| end", __FILE__, __LINE__)
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, platform._platform, [])
      proj.generate_packages(false)
      expect(proj._project.generate_package).to eq([])
    end
  end

  describe '#get_rpm_ghost_files' do
    it 'returns an empty array when there are no ghost files' do
      proj = Vanagon::Project.new('test-ghost', platform)
      expect(proj.get_rpm_ghost_files).to eq([])
    end

    it 'returns ghost files when some are set' do
      proj = Vanagon::Project.new('test-ghosts', platform)
      comp = Vanagon::Component.new('ghosts', {}, {})
      comp.add_rpm_ghost_file('ghost')
      proj.components << comp
      expect(proj.get_rpm_ghost_files).to eq(['ghost'])
    end
  end
end
