describe XAeonAgents::Cli, '#start_task' do
  describe 'using a new branch' do
    it 'creates a worktree, a new branch, pushes it and opens VSCodium' do
      branch_name = 'feature/new-task'
      worktree_dir = ".worktrees/#{branch_name.tr('/', '_')}"
      with_git_workspace(
        files: { 'test.txt' => "original\n" },
        remotes: { 'github' => 'git@github.com:owner/repo.git' }
      ) do
        main_git = Git.open(Dir.pwd)
        main_sha = main_git.gcommit('HEAD').sha
        main_branch = main_git.current_branch

        mock_git_push
        allow($stdin).to receive(:gets).and_return(branch_name)

        vscodium_command = nil
        stub_command(
          "VSCodium.exe \"#{worktree_dir}\"",
          stdout: proc do |cmd|
            vscodium_command = cmd
            ''
          end
        )

        run_cli 'start-task'
        expect(exit_status).to eq 0

        # The git worktree is initialized properly
        expect(Dir).to exist(worktree_dir)
        expect(File).to exist(File.join(worktree_dir, '.git'))
        expect(Git.open(worktree_dir).current_branch).to eq branch_name

        # A new branch has been created
        expect(Git.open(Dir.pwd).branches.map(&:name)).to include(branch_name)

        # The new branch has been pushed
        expect(git_pushes).to eq [
          {
            url: 'git@github.com:owner/repo.git',
            branch: branch_name,
            options: { set_upstream: true }
          }
        ]

        # VSCodium has been run within this worktree
        expect(vscodium_command).to eq "VSCodium.exe \"#{worktree_dir}\""

        # The main repo (not worktree) is still on the main branch with the same SHA
        expect(Git.open(Dir.pwd).current_branch).to eq main_branch
        expect(Git.open(Dir.pwd).gcommit('HEAD').sha).to eq main_sha
      end
    end
  end

  describe 'using an existing branch' do
    it 'keeps the existing branch, pushes it and opens VSCodium' do
      branch_name = 'feature/existing-task'
      worktree_dir = ".worktrees/#{branch_name.tr('/', '_')}"
      with_git_workspace(
        files: { 'test.txt' => "original\n" },
        remotes: { 'github' => 'git@github.com:owner/repo.git' }
      ) do
        # Create the branch in advance (without checking it out)
        Git.open(Dir.pwd).branch(branch_name).create
        branch_sha = Git.open(Dir.pwd).gcommit(branch_name).sha

        main_git = Git.open(Dir.pwd)
        main_sha = main_git.gcommit('HEAD').sha
        main_branch = main_git.current_branch

        mock_git_push
        allow($stdin).to receive(:gets).and_return(branch_name)

        vscodium_command = nil
        stub_command(
          "VSCodium.exe \"#{worktree_dir}\"",
          stdout: proc do |cmd|
            vscodium_command = cmd
            ''
          end
        )

        run_cli 'start-task'
        expect(exit_status).to eq 0

        # The git worktree is initialized properly
        expect(Dir).to exist(worktree_dir)
        expect(File).to exist(File.join(worktree_dir, '.git'))
        expect(Git.open(worktree_dir).current_branch).to eq branch_name

        # The existing branch is kept with the same SHA as before the run
        expect(Git.open(Dir.pwd).gcommit(branch_name).sha).to eq branch_sha

        # The existing branch has been pushed
        expect(git_pushes).to eq [
          {
            url: 'git@github.com:owner/repo.git',
            branch: branch_name,
            options: { set_upstream: true }
          }
        ]

        # VSCodium has been run within this worktree
        expect(vscodium_command).to eq "VSCodium.exe \"#{worktree_dir}\""

        # The main repo (not worktree) is still on the main branch with the same SHA
        expect(Git.open(Dir.pwd).current_branch).to eq main_branch
        expect(Git.open(Dir.pwd).gcommit('HEAD').sha).to eq main_sha
      end
    end
  end

  describe 'calling start_task twice on the same branch' do
    it 'is idempotent: does not recreate the worktree and keeps the same branch' do
      branch_name = 'feature/idempotent'
      worktree_dir = ".worktrees/#{branch_name.tr('/', '_')}"
      with_git_workspace(
        files: { 'test.txt' => "original\n" },
        remotes: { 'github' => 'git@github.com:owner/repo.git' }
      ) do
        main_git = Git.open(Dir.pwd)
        main_sha = main_git.gcommit('HEAD').sha
        main_branch = main_git.current_branch

        mock_git_push
        allow($stdin).to receive(:gets).and_return(branch_name)

        vscodium_command = nil
        stub_command(
          "VSCodium.exe \"#{worktree_dir}\"",
          stdout: proc do |cmd|
            vscodium_command = cmd
            ''
          end
        )

        # First call
        run_cli 'start-task'
        expect(exit_status).to eq 0

        expect(Dir).to exist(worktree_dir)
        branch_sha = Git.open(Dir.pwd).gcommit(branch_name).sha
        # Add a marker file in the worktree to detect if it gets recreated
        File.write(File.join(worktree_dir, 'marker.txt'), "kept\n")

        # Second call (idempotent)
        run_cli 'start-task'
        expect(exit_status).to eq 0

        # The worktree is still there, untouched (idempotent: not recreated)
        expect(Dir).to exist(worktree_dir)
        expect(File).to exist(File.join(worktree_dir, 'marker.txt'))

        # The branch is kept with the same SHA (no new commit, no duplicate creation)
        expect(Git.open(Dir.pwd).gcommit(branch_name).sha).to eq branch_sha

        # VSCodium has been run again within this worktree
        expect(vscodium_command).to eq "VSCodium.exe \"#{worktree_dir}\""

        # The main repo (not worktree) is still on the main branch with the same SHA
        expect(Git.open(Dir.pwd).current_branch).to eq main_branch
        expect(Git.open(Dir.pwd).gcommit('HEAD').sha).to eq main_sha
      end
    end
  end

  describe 'using the --branch CLI option' do
    it 'creates a worktree with the given branch without reading STDIN' do
      branch_name = 'feature/cli-branch'
      worktree_dir = ".worktrees/#{branch_name.tr('/', '_')}"
      with_git_workspace(
        files: { 'test.txt' => "original\n" },
        remotes: { 'github' => 'git@github.com:owner/repo.git' }
      ) do
        main_git = Git.open(Dir.pwd)
        main_sha = main_git.gcommit('HEAD').sha
        main_branch = main_git.current_branch

        # STDIN should NOT be used: ensure any read from it fails the test
        allow($stdin).to receive(:gets).and_raise('STDIN should not be read when --branch is given')

        mock_git_push

        vscodium_command = nil
        stub_command(
          "VSCodium.exe \"#{worktree_dir}\"",
          stdout: proc do |cmd|
            vscodium_command = cmd
            ''
          end
        )

        run_cli 'start-task', '--branch', branch_name
        expect(exit_status).to eq 0

        # The git worktree is initialized properly with the given branch
        expect(Dir).to exist(worktree_dir)
        expect(File).to exist(File.join(worktree_dir, '.git'))
        expect(Git.open(worktree_dir).current_branch).to eq branch_name

        # A new branch has been created
        expect(Git.open(Dir.pwd).branches.map(&:name)).to include(branch_name)

        # The new branch has been pushed
        expect(git_pushes).to eq [
          {
            url: 'git@github.com:owner/repo.git',
            branch: branch_name,
            options: { set_upstream: true }
          }
        ]

        # VSCodium has been run within this worktree
        expect(vscodium_command).to eq "VSCodium.exe \"#{worktree_dir}\""

        # The main repo (not worktree) is still on the main branch with the same SHA
        expect(Git.open(Dir.pwd).current_branch).to eq main_branch
        expect(Git.open(Dir.pwd).gcommit('HEAD').sha).to eq main_sha
      end
    end
  end

  describe 'using a session-id and re-calling start_task' do
    it 're-creates the worktree and pushes the new commit when called again with the same session-id' do
      branch_name = 'feature/session-task'
      worktree_dir = ".worktrees/#{branch_name.tr('/', '_')}"
      session_id = 'test-session-start-task'
      with_git_workspace(
        files: { 'test.txt' => "original\n" },
        remotes: { 'github' => 'git@github.com:owner/repo.git' }
      ) do
        main_git = Git.open(Dir.pwd)
        main_sha = main_git.gcommit('HEAD').sha
        main_branch = main_git.current_branch

        mock_git_push
        allow($stdin).to receive(:gets).and_return(branch_name)

        vscodium_command = nil
        stub_command(
          "VSCodium.exe \"#{worktree_dir}\"",
          stdout: proc do |cmd|
            vscodium_command = cmd
            ''
          end
        )

        # First call with a session-id
        run_cli 'start-task', '--session-id', session_id
        expect(exit_status).to eq 0

        expect(Dir).to exist(worktree_dir)
        expect(Git.open(worktree_dir).current_branch).to eq branch_name

        # Create a new commit in the branch (in the worktree)
        worktree_git = Git.open(worktree_dir)
        File.write(File.join(worktree_dir, 'new_file.txt'), "new content\n")
        worktree_git.add('new_file.txt')
        worktree_git.commit('Add new file')
        new_commit_sha = worktree_git.gcommit('HEAD').sha
        expect(new_commit_sha).not_to eq main_sha

        # Remove the worktree
        worktree_git.lib.worktree_remove(worktree_dir)
        expect(Dir).not_to exist(worktree_dir)

        # Second call with the SAME session-id: should re-create the worktree and push the new commit
        run_cli 'start-task', '--session-id', session_id
        expect(exit_status).to eq 0

        # The worktree has been re-created
        expect(Dir).to exist(worktree_dir)
        expect(File).to exist(File.join(worktree_dir, '.git'))
        expect(Git.open(worktree_dir).current_branch).to eq branch_name

        # The new commit is present in the re-created worktree
        expect(Git.open(worktree_dir).gcommit('HEAD').sha).to eq new_commit_sha

        # The branch has been pushed (twice: once initially, once after the new commit)
        expect(git_pushes.size).to eq 2
        expect(git_pushes.last).to eq(
          {
            url: 'git@github.com:owner/repo.git',
            branch: branch_name,
            options: { set_upstream: true }
          }
        )

        # VSCodium has been run again within this worktree
        expect(vscodium_command).to eq "VSCodium.exe \"#{worktree_dir}\""

        # The main repo (not worktree) is still on the main branch with the same SHA
        expect(Git.open(Dir.pwd).current_branch).to eq main_branch
        expect(Git.open(Dir.pwd).gcommit('HEAD').sha).to eq main_sha
      end
    end
  end
end
