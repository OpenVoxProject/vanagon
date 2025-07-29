platform "osx-14-x86_64" do |plat|
  plat.servicetype "launchd"
  plat.servicedir "/Library/LaunchDaemons"
  plat.codename "sonoma"

  plat.provision_with "export HOMEBREW_NO_EMOJI=true"
  plat.provision_with "export HOMEBREW_VERBOSE=true"
  plat.provision_with "export HOMEBREW_NO_ANALYTICS=1"

  plat.provision_with "sudo dscl . -create /Users/test"
  plat.provision_with "sudo dscl . -create /Users/test UserShell /bin/bash"
  plat.provision_with "sudo dscl . -create /Users/test UniqueID 1001"
  plat.provision_with "sudo dscl . -create /Users/test PrimaryGroupID 1000"
  plat.provision_with "sudo dscl . -create /Users/test NFSHomeDirectory /Users/test"
  plat.provision_with "sudo dscl . -passwd /Users/test password"
  plat.provision_with "sudo dscl . -merge /Groups/admin GroupMembership test"
  plat.provision_with "echo 'test ALL=(ALL:ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/username > /dev/null"
  #plat.provision_with "sudo mkdir -p /etc/homebrew"
  #plat.provision_with "cd /etc/homebrew"
  plat.provision_with "sudo createhomedir -c -u test"
  if File.directory?("/usr/local/var/homebrew")
    plat.provision_with "sudo chown -R test /usr/local/var/homebrew /usr/local/share/zsh /usr/local/share/zsh/site-functions \
    /usr/local/etc/bash_completion.d /usr/local/lib/pkgconfig /usr/local/share/aclocal /usr/local/share/locale"

    # MacOS changing ownership of the files inside the directories, but not the directory ownership itself
    plat.provision_with "sudo chown test /usr/local/var/homebrew /usr/local/share/zsh /usr/local/share/zsh/site-functions \
    /usr/local/etc/bash_completion.d /usr/local/lib/pkgconfig /usr/local/share/aclocal /usr/local/share/locale"
  else
    plat.provision_with %Q(sudo su test -c 'echo | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"')
  end
  plat.vmpooler_template "macos-14-x86_64"
end
