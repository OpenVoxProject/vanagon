require 'tempfile'
require 'vanagon/platform'
require 'vanagon/project'
require 'vanagon/common'

describe "Vanagon::Platform::MacOS" do
  let(:block) {
    %Q[ platform "macos-all-x86_64" do |plat|
    end
    ]
  }
  let(:plat) { Vanagon::Platform::DSL.new('macos-all-x86_64') }

  before do
    plat.instance_eval(block)
  end

  describe "macos has a different mktemp" do
    it "uses the right mktemp options" do
      expect(plat._platform.send(:mktemp)).to eq("mktemp -d -t 'tmp'")
    end
  end

  describe "uninstaller" do
    let(:configdir) { '/a/b/c' }
    let(:template) { File.expand_path('../../../../resources/macos/uninstaller.tool.erb', __dir__) }
    let(:project_block) {
      %Q[ project 'test-fixture' do |proj|
        proj.identifier 'org.example'
        proj.directory '/opt/puppetlabs/test-fixture'
        proj.directory '/opt/puppetlabs/bin'
      end
      ]
    }
    let(:uninstaller) do
      proj = Vanagon::Project::DSL.new('test-fixture', configdir, plat._platform, [])
      proj.instance_eval(project_block)
      project = proj._project
      project.erb_string(template, project.instance_eval { binding })
    end

    it "is valid bash" do
      Tempfile.create('uninstaller') do |file|
        file.write(uninstaller)
        file.flush
        expect(system('/bin/bash', '-n', file.path)).to be(true)
      end
    end

    it "identifies the package by its receipt" do
      expect(uninstaller).to include('pkg_id="org.example.test-fixture"')
    end

    it "removes the files recorded in the package receipt" do
      expect(uninstaller).to include('--files "${pkg_id}"')
    end

    it "forgets the package receipt" do
      expect(uninstaller).to include('--forget "${pkg_id}"')
    end

    it "removes declared directories only when no other package claims them" do
      expect(uninstaller).to include("remove_unshared_directory '/opt/puppetlabs/test-fixture'")
      expect(uninstaller).to include("remove_unshared_directory '/opt/puppetlabs/bin'")
    end

    it "does not unconditionally remove declared directories" do
      expect(uninstaller).not_to match(%r{^/bin/rm -Rf /opt/puppetlabs})
    end
  end
end
