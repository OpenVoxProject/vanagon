platform "debian-13-aarch64" do |plat|
  plat.servicedir "/lib/systemd/system"
  plat.defaultdir "/etc/default"
  plat.servicetype "systemd"
  plat.codename "trixie"

  packages = %w(
    build-essential
    cmake
    curl
    debhelper
    devscripts
    fakeroot
    make
    pkg-config
    quilt
    rsync
    systemd
  )
  plat.provision_with "export DEBIAN_FRONTEND=noninteractive; apt-get update -qq; apt-get install -qy --no-install-recommends #{packages.join(' ')}"
  plat.install_build_dependencies_with "DEBIAN_FRONTEND=noninteractive; apt-get install -qy --no-install-recommends "
  plat.vmpooler_template "debian-13-arm64"
  # Change to "debian:13" on final release
  plat.docker_image "debian:trixie"
  plat.docker_arch "linux/arm64"
end
