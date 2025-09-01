require 'vanagon/platform'

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
end

