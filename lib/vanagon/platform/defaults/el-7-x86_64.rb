platform "el-7-x86_64" do |plat|
  plat.servicedir "/usr/lib/systemd/system"
  plat.defaultdir "/etc/sysconfig"
  plat.servicetype "systemd"

  plat.add_build_repository "https://archives.fedoraproject.org/pub/archive/epel/7/x86_64/Packages/e/epel-release-7-14.noarch.rpm"
  packages = %w(
    autoconf
    automake
    cmake
    cmake3
    createrepo
    curl
    gcc
    gcc-c++
    make
    oracle-softwarecollection-release-el7
    rpmdevtools
    rpm-libs
    rpm-sign
    rsync
    systemd
    yum-utils
    which
  )
  plat.provision_with "yum install --assumeyes #{packages.join(' ')}"
  plat.provision_with "yum install --assumeyes devtoolset-7-gcc devtoolset-7-gcc-c++"
  plat.provision_with "scl enable devtoolset-7 bash"
  plat.install_build_dependencies_with "yum install --assumeyes"
  plat.vmpooler_template "redhat-7-x86_64"
  plat.docker_image "oraclelinux:7"
  plat.docker_arch "linux/amd64"
end
