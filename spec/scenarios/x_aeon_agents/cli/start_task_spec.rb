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
end
