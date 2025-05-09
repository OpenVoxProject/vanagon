require 'vanagon/platform'
require 'vanagon/project'
require 'vanagon/utilities/extra_files_signer'

describe Vanagon::Utilities::ExtraFilesSigner do
  let(:platform_block) do
    %( platform "osx-11-x86_64" do |plat|
    end
    )
  end
  let (:project_block) do
    <<-HERE.undent
      project 'test-fixture' do |proj|
        proj.version '0.0.0'
      end
    HERE
  end
  let(:configdir) { '/a/b/c' }
  let(:platform) { Vanagon::Platform::DSL.new('osx-11-x86_64') }
  let(:project) do
    Vanagon::Project::DSL.new('test-fixture', configdir, platform._platform, [])
  end
  let(:mktemp) { '/tmp/xyz' }
  let(:source_dir) { '/dir/source_dir' }

  before do
    allow(VanagonLogger).to receive(:error)
    platform.instance_eval(platform_block)
    project.instance_eval(project_block)
    allow(Vanagon::Utilities).to receive(:remote_ssh_command).and_return(mktemp)
  end

  describe '.commands' do
    context 'without extra files to sign' do
      it 'returns empty array' do
        commands = Vanagon::Utilities::ExtraFilesSigner.commands(project._project, mktemp, source_dir)
        expect(commands).to eql([])
      end
    end

    context 'with extra files to sign' do
      let (:project_block) do
        <<-HERE.undent
          project 'test-fixture' do |proj|
            proj.version '0.0.0'
            proj.extra_file_to_sign '/test1/a.rb'
            proj.extra_file_to_sign '/test2/b.rb'
            proj.signing_hostname('abc')
            proj.signing_username('test')
             proj.signing_command('codesign %{file}')
          end
        HERE
      end

      context 'when it cannot connect to signing hostname' do
        before do
          allow(Vanagon::Utilities).to receive(:remote_ssh_command)
            .with('test@abc', '/tmp/xyz 2>/dev/null', return_command_output: true)
            .and_raise RuntimeError
        end

        it 'returns empty array' do
          commands = Vanagon::Utilities::ExtraFilesSigner.commands(project._project, mktemp, source_dir)
          expect(commands).to eql([])
        end

        it 'logs error' do
          Vanagon::Utilities::ExtraFilesSigner.commands(project._project, mktemp, source_dir)
          expect(VanagonLogger).to have_received(:error).with(/Unable to connect to test@abc/)
        end

        it 'fails the build if VANAGON_FORCE_SIGNING is set' do
          allow(ENV).to receive(:[]).with('VANAGON_FORCE_SIGNING').and_return('true')
          expect {
            Vanagon::Utilities::ExtraFilesSigner.commands(project._project, mktemp, source_dir)
          }.to raise_error(RuntimeError)
        end
      end

      context 'when success' do
        context 'when macos' do
          it 'generates signing commands for each file using --extended-attributes' do
            stub_const('ENV', ENV.to_hash.merge('VANAGON_SSH_KEY' => nil))
            commands = Vanagon::Utilities::ExtraFilesSigner.commands(project._project, mktemp, source_dir)
            expected_commands = [
              %q(/usr/bin/ssh -p 22  -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no test@abc "echo > /tmp/xyz/sign_extra_file"),
              %q(/usr/bin/ssh -p 22  -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no test@abc "echo 'codesign /tmp/xyz/a.rb' >> /tmp/xyz/sign_extra_file"),
              %q(rsync -e '/usr/bin/ssh -p 22  -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no' --verbose --recursive --hard-links --links --no-perms --no-owner --no-group --extended-attributes $(tempdir)/dir/source_dir/test1/a.rb test@abc:/tmp/xyz),
              %q(/usr/bin/ssh -p 22  -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no test@abc /bin/bash /tmp/xyz/sign_extra_file),
              %q(rsync -e '/usr/bin/ssh -p 22  -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no' --verbose --recursive --hard-links --links --no-perms --no-owner --no-group --extended-attributes test@abc:/tmp/xyz/a.rb $(tempdir)/dir/source_dir/test1/a.rb),
              %q(/usr/bin/ssh -p 22  -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no test@abc "echo > /tmp/xyz/sign_extra_file"),
              %q(/usr/bin/ssh -p 22  -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no test@abc "echo 'codesign /tmp/xyz/b.rb' >> /tmp/xyz/sign_extra_file"),
              %q(rsync -e '/usr/bin/ssh -p 22  -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no' --verbose --recursive --hard-links --links --no-perms --no-owner --no-group --extended-attributes $(tempdir)/dir/source_dir/test2/b.rb test@abc:/tmp/xyz),
              %q(/usr/bin/ssh -p 22  -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no test@abc /bin/bash /tmp/xyz/sign_extra_file),
              %q(rsync -e '/usr/bin/ssh -p 22  -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no' --verbose --recursive --hard-links --links --no-perms --no-owner --no-group --extended-attributes test@abc:/tmp/xyz/b.rb $(tempdir)/dir/source_dir/test2/b.rb)
            ]
            expect(commands[0]).to match(expected_commands[0])
            expect(commands[1]).to match(expected_commands[1])
            expect(commands[2]).to match(expected_commands[2])
            expect(commands[3]).to match(expected_commands[3])
            expect(commands[4]).to match(expected_commands[4])
            expect(commands[5]).to match(expected_commands[5])
            expect(commands[6]).to match(expected_commands[6])
            expect(commands[7]).to match(expected_commands[7])
          end
        end

        context 'when other platform' do
          let(:platform_block) do
            %( platform "windows-2012r2-x86_64" do |plat|
            end
            )
          end

          let(:platform) { Vanagon::Platform::DSL.new('windows-2012r2-x86_64') }

          it 'generates signing commands for each file' do
            stub_const('ENV', ENV.to_hash.merge('VANAGON_SSH_KEY' => nil))
            commands = Vanagon::Utilities::ExtraFilesSigner.commands(project._project, mktemp, source_dir)
            expected_commands = [
              %q(/usr/bin/ssh -p 22  -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no test@abc "echo > /tmp/xyz/sign_extra_file"),
              %q(/usr/bin/ssh -p 22  -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no test@abc "echo 'codesign /tmp/xyz/a.rb' >> /tmp/xyz/sign_extra_file"),
              %q(rsync -e '/usr/bin/ssh -p 22  -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no' --verbose --recursive --hard-links --links --no-perms --no-owner --no-group  $(tempdir)/dir/source_dir/test1/a.rb test@abc:/tmp/xyz),
              %q(/usr/bin/ssh -p 22  -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no test@abc /bin/bash /tmp/xyz/sign_extra_file),
              %q(rsync -e '/usr/bin/ssh -p 22  -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no' --verbose --recursive --hard-links --links --no-perms --no-owner --no-group  test@abc:/tmp/xyz/a.rb $(tempdir)/dir/source_dir/test1/a.rb),
              %q(/usr/bin/ssh -p 22  -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no test@abc "echo > /tmp/xyz/sign_extra_file"),
              %q(/usr/bin/ssh -p 22  -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no test@abc "echo 'codesign /tmp/xyz/b.rb' >> /tmp/xyz/sign_extra_file"),
              %q(rsync -e '/usr/bin/ssh -p 22  -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no' --verbose --recursive --hard-links --links --no-perms --no-owner --no-group  $(tempdir)/dir/source_dir/test2/b.rb test@abc:/tmp/xyz),
              %q(/usr/bin/ssh -p 22  -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no test@abc /bin/bash /tmp/xyz/sign_extra_file),
              %q(rsync -e '/usr/bin/ssh -p 22  -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no' --verbose --recursive --hard-links --links --no-perms --no-owner --no-group  test@abc:/tmp/xyz/b.rb $(tempdir)/dir/source_dir/test2/b.rb)
            ]
            expect(commands[0]).to match(expected_commands[0])
            expect(commands[1]).to match(expected_commands[1])
            expect(commands[2]).to match(expected_commands[2])
            expect(commands[3]).to match(expected_commands[3])
            expect(commands[4]).to match(expected_commands[4])
            expect(commands[5]).to match(expected_commands[5])
            expect(commands[6]).to match(expected_commands[6])
            expect(commands[7]).to match(expected_commands[7])
          end
        end
      end
    end
  end
end
