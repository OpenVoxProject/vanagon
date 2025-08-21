platform "ubuntu-25.04-amd64" do |plat|
  plat.servicedir "/lib/systemd/system"
  plat.defaultdir "/etc/default"
  plat.servicetype "systemd"
  plat.codename "noble"

  packages = %w(
    autoconf
    build-essential
    cmake
    curl
    debhelper
    devscripts
    fakeroot
    libbz2-dev
    libreadline-dev
    libselinux1-dev
    openjdk-8-jre-headless
    pkg-config
    quilt
    rsync
    swig
    systemd
    systemtap-sdt-dev
    zlib1g-dev
  )
  plat.provision_with "export DEBIAN_FRONTEND=noninteractive; apt-get update -qq; apt-get install -qy --no-install-recommends #{packages.join(' ')}"
  plat.install_build_dependencies_with "DEBIAN_FRONTEND=noninteractive; apt-get install -qy --no-install-recommends "
  plat.vmpooler_template "ubuntu-2504-x86_64"
  plat.docker_image "ubuntu:25.04"
  plat.docker_arch 'linux/amd64'
end
