platform 'osx-15-arm64' do |plat|
    plat.brew '/opt/homebrew/bin/brew'
    plat.servicetype 'launchd'
    plat.servicedir '/Library/LaunchDaemons'
    plat.codename 'sequoia'

    # Must already have homebrew installed
    plat.provision_with 'export HOMEBREW_NO_EMOJI=true'
    plat.provision_with 'export HOMEBREW_VERBOSE=true'
    plat.provision_with "export HOMEBREW_NO_ANALYTICS=1"

    plat.vmpooler_template 'macos-15-arm64'
  end
