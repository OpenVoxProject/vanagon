platform "sles-16-x86_64" do |plat|
  plat.servicedir "/usr/lib/systemd/system"
  plat.defaultdir "/etc/sysconfig"
  plat.servicetype "systemd"

  packages = %w(
    aaa_base
    autoconf
    automake
    cmake
    curl
    gcc
    gcc-c++
    gettext-tools
    make
    rpm-build
    rsync
    systemd
    which
  )
  plat.provision_with "zypper -n install -y #{packages.join(' ')}"
  plat.install_build_dependencies_with "zypper -n --no-gpg-checks install -y"
  plat.vmpooler_template "sles-16-x86_64"
  plat.docker_registry "registry.suse.com/bci"
  plat.docker_image "bci-base:16.0"
  plat.docker_arch "linux/arm64"
end
