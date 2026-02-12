platform "sles-15-x86_64" do |plat|
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
  plat.provision_with "zypper -n --no-gpg-checks install -y #{packages.join(' ')}"
  plat.install_build_dependencies_with "zypper -n --no-gpg-checks install -y"
  plat.vmpooler_template "sles-15-x86_64"
  plat.docker_registry "registry.suse.com/suse"
  # sles15.5 -> sles15.6 updates glibc in a breaking release.
  # If built with 15.6 glibc, the openvox-agent on 15.5 will be broken.
  # We bet on glibc backward compability and use the older sles/glibc to build.
  plat.docker_image "sle15:15.5"
  plat.docker_arch "linux/amd64"
end
