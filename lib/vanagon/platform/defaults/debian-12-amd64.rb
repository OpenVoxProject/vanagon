platform "debian-12-amd64" do |plat|
  plat.servicedir "/lib/systemd/system"
  plat.defaultdir "/etc/default"
  plat.servicetype "systemd"
  plat.codename "bookworm"

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
  plat.vmpooler_template "debian-12-x86_64"
  plat.docker_image "debian:12"
  plat.docker_arch "linux/amd64"
end
