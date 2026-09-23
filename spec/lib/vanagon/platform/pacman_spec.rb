require 'vanagon/platform/pacman'
require 'vanagon/project'

describe Vanagon::Platform::Pacman do
  let(:platform) { described_class.new('archlinux-rolling-x86_64') }

  describe '#package_name' do
    it 'returns a platform-specific tar archive name' do
      project = instance_double(Vanagon::Project, name: 'openbolt', version: '8.0.0')

      expect(platform.package_name(project)).to eq('openbolt-8.0.0-archlinux-rolling-x86_64.tar.gz')
    end
  end

  describe '#install_build_dependencies' do
    it 'uses pacman without prompting' do
      expect(platform.install_build_dependencies(%w[curl make])).to eq('pacman -Syu --noconfirm --needed curl make')
    end
  end
end
