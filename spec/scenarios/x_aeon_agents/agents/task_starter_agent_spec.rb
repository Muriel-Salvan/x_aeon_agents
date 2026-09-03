require 'git'
require_relative 'shared_examples/common_behavior'

describe XAeonAgents::Agents::TaskStarterAgent do
  it_behaves_like 'an agent with common behavior', described_class

  describe 'using a new branch' do
    it 'creates a worktree, a new branch and pushes it' do
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

        described_class.new(session_id: nil).run(branch_name: branch_name)

        # The git worktree is initialized properly
        expect(Dir).to exist(worktree_dir)
        expect(File).to exist(File.join(worktree_dir, '.git'))
        expect(Git.open(worktree_dir).current_branch).to eq branch_name

        # A new branch has been created
        expect(Git.open(Dir.pwd).branches.map(&:name)).to include(branch_name)

        # The new branch has been pushed
        expect(git_pushes).to eq [
          ['--set-upstream', 'github', branch_name]
        ]

        # The main repo (not worktree) is still on the main branch with the same SHA
        expect(Git.open(Dir.pwd).current_branch).to eq main_branch
        expect(Git.open(Dir.pwd).gcommit('HEAD').sha).to eq main_sha
      end
    end
  end

  describe 'using an existing branch' do
    it 'keeps the existing branch and pushes it' do
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

        described_class.new(session_id: nil).run(branch_name: branch_name)

        # The git worktree is initialized properly
        expect(Dir).to exist(worktree_dir)
        expect(File).to exist(File.join(worktree_dir, '.git'))
        expect(Git.open(worktree_dir).current_branch).to eq branch_name

        # The existing branch is kept with the same SHA as before the run
        expect(Git.open(Dir.pwd).gcommit(branch_name).sha).to eq branch_sha

        # The existing branch has been pushed
        expect(git_pushes).to eq [
          ['--set-upstream', 'github', branch_name]
        ]

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

        # First call
        described_class.new(session_id: nil).run(branch_name: branch_name)

        expect(Dir).to exist(worktree_dir)
        branch_sha = Git.open(Dir.pwd).gcommit(branch_name).sha
        # Add a marker file in the worktree to detect if it gets recreated
        File.write(File.join(worktree_dir, 'marker.txt'), "kept\n")

        # Second call (idempotent)
        described_class.new(session_id: nil).run(branch_name: branch_name)

        # The worktree is still there, untouched (idempotent: not recreated)
        expect(Dir).to exist(worktree_dir)
        expect(File).to exist(File.join(worktree_dir, 'marker.txt'))

        # The branch is kept with the same SHA (no new commit, no duplicate creation)
        expect(Git.open(Dir.pwd).gcommit(branch_name).sha).to eq branch_sha

        # The main repo (not worktree) is still on the main branch with the same SHA
        expect(Git.open(Dir.pwd).current_branch).to eq main_branch
        expect(Git.open(Dir.pwd).gcommit('HEAD').sha).to eq main_sha
      end
    end
  end

  describe 'using the branch_name parameter (equivalent of the --branch CLI option)' do
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
        allow($stdin).to receive(:gets).and_raise('STDIN should not be read when the branch name is given as parameter')

        mock_git_push

        described_class.new(session_id: nil).run(branch_name: branch_name)

        # The git worktree is initialized properly with the given branch
        expect(Dir).to exist(worktree_dir)
        expect(File).to exist(File.join(worktree_dir, '.git'))
        expect(Git.open(worktree_dir).current_branch).to eq branch_name

        # A new branch has been created
        expect(Git.open(Dir.pwd).branches.map(&:name)).to include(branch_name)

        # The new branch has been pushed
        expect(git_pushes).to eq [
          ['--set-upstream', 'github', branch_name]
        ]

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

        # First call with a session-id
        described_class.new(session_id: session_id).run(branch_name: branch_name)

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
        described_class.new(session_id: session_id).run(branch_name: branch_name)

        # The worktree has been re-created
        expect(Dir).to exist(worktree_dir)
        expect(File).to exist(File.join(worktree_dir, '.git'))
        expect(Git.open(worktree_dir).current_branch).to eq branch_name

        # The new commit is present in the re-created worktree
        expect(Git.open(worktree_dir).gcommit('HEAD').sha).to eq new_commit_sha

        # The branch has been pushed (twice: once initially, once after the new commit)
        expect(git_pushes.size).to eq 2
        expect(git_pushes.last).to eq ['--set-upstream', 'github', branch_name]

        # The main repo (not worktree) is still on the main branch with the same SHA
        expect(Git.open(Dir.pwd).current_branch).to eq main_branch
        expect(Git.open(Dir.pwd).gcommit('HEAD').sha).to eq main_sha
      end
    end

    describe 'when the target directory exists but is not a git worktree' do
      it 'raises an error with a proper message and does not create a worktree' do
        branch_name = 'feature/existing-dir'
        worktree_dir = ".worktrees/#{branch_name.tr('/', '_')}"
        with_git_workspace(
          files: { 'test.txt' => "original\n" },
          remotes: { 'github' => 'git@github.com:owner/repo.git' }
        ) do
          # Create a plain directory (not a worktree) at the target path
          FileUtils.mkdir_p(worktree_dir)
          File.write(File.join(worktree_dir, 'some_file.txt'), "not a worktree\n")

          mock_git_push

          # The agent must fail with an explicit error
          expect do
            described_class.new(session_id: nil).run(branch_name: branch_name)
          end.to raise_error(XAeonAgents::Agents::TaskStarterAgent::TaskStarterError, /is not a git worktree/)

          # No worktree was created (.git pointer file is absent)
          expect(File).not_to exist(File.join(worktree_dir, '.git'))
          # The plain directory is left untouched
          expect(File).to exist(File.join(worktree_dir, 'some_file.txt'))
        end
      end
    end

    describe 'when the target directory is a worktree on a different branch' do
      it 'raises an error with a proper message' do
        requested_branch = 'feature/requested'
        other_branch = 'feature/other'
        worktree_dir = ".worktrees/#{requested_branch.tr('/', '_')}"
        with_git_workspace(
          files: { 'test.txt' => "original\n" },
          remotes: { 'github' => 'git@github.com:owner/repo.git' }
        ) do
          # Create the other branch and a worktree on it at the requested path
          Git.open(Dir.pwd).branch(other_branch).create
          Git.open(Dir.pwd).lib.worktree_add(worktree_dir, other_branch)

          mock_git_push

          # The agent must fail with an explicit error
          expect do
            described_class.new(session_id: nil).run(branch_name: requested_branch)
          end.to raise_error(
            XAeonAgents::Agents::TaskStarterAgent::TaskStarterError,
            /already a git worktree on branch '#{other_branch}'.*requested branch '#{requested_branch}'/m
          )

          # The existing worktree is left untouched on the other branch
          expect(Git.open(worktree_dir).current_branch).to eq other_branch
        end
      end
    end
  end

  describe 'when the config DSL defines setup_project steps' do
    it 'executes the setup steps in the freshly created worktree' do
      branch_name = 'feature/with-setup-steps'
      worktree_dir = ".worktrees/#{branch_name.tr('/', '_')}"
      with_git_workspace(
        files: { 'test.txt' => "original\n" },
        remotes: { 'github' => 'git@github.com:owner/repo.git' }
      ) do
        # Define the setup steps through the config DSL, in the project's config file
        File.write('.x_aeon_agents.rb', <<~CONFIG)
          setup_project do
            XAeonAgents::Helpers.run_cmd 'echo setup-step'
          end
        CONFIG
        # Load the config file, like the CLI does before running the agent
        XAeonAgents::Config.load

        mock_git_push
        setup_commands = []
        stub_command(
          'echo setup-step',
          stdout: proc do |cmd|
            setup_commands << [cmd, Dir.pwd]
            ''
          end
        )

        described_class.new(session_id: nil).run(branch_name: branch_name)

        # The worktree has been created
        expect(Dir).to exist(worktree_dir)
        expect(Git.open(worktree_dir).current_branch).to eq branch_name

        # The setup step has been executed exactly once, from within the fresh worktree
        expect(setup_commands).to eq [['echo setup-step', File.expand_path(worktree_dir)]]

        # The rest of the process has been performed as usual
        expect(git_pushes).to eq [['--set-upstream', 'github', branch_name]]
      end
    end
  end

  describe 'when the config DSL does not define setup_project steps' do
    it 'does not execute any setup step in the freshly created worktree' do
      branch_name = 'feature/without-setup-steps'
      worktree_dir = ".worktrees/#{branch_name.tr('/', '_')}"
      with_git_workspace(
        files: { 'test.txt' => "original\n" },
        remotes: { 'github' => 'git@github.com:owner/repo.git' }
      ) do
        mock_git_push
        setup_commands = []
        stub_command(
          /echo/,
          stdout: proc do |cmd|
            setup_commands << cmd
            ''
          end
        )

        described_class.new(session_id: nil).run(branch_name: branch_name)

        # No setup step has been executed
        expect(setup_commands).to be_empty

        # The worktree has been created as usual
        expect(Dir).to exist(worktree_dir)
        expect(Git.open(worktree_dir).current_branch).to eq branch_name
      end
    end
  end

  describe 'calling start_task twice on the same branch with setup_project steps' do
    it 'executes the setup steps only for the freshly created worktree' do
      branch_name = 'feature/setup-steps-idempotent'
      with_git_workspace(
        files: { 'test.txt' => "original\n" },
        remotes: { 'github' => 'git@github.com:owner/repo.git' }
      ) do
        File.write('.x_aeon_agents.rb', <<~CONFIG)
          setup_project do
            XAeonAgents::Helpers.run_cmd 'echo setup-step'
          end
        CONFIG
        # Load the config file, like the CLI does before running the agent
        XAeonAgents::Config.load

        mock_git_push
        setup_commands = []
        stub_command(
          'echo setup-step',
          stdout: proc do |cmd|
            setup_commands << cmd
            ''
          end
        )

        # First call: the worktree is freshly created
        described_class.new(session_id: nil).run(branch_name: branch_name)
        expect(setup_commands.size).to eq 1

        # Second call: the worktree already exists
        described_class.new(session_id: nil).run(branch_name: branch_name)

        # The setup steps have been executed only once, for the fresh worktree only
        expect(setup_commands.size).to eq 1
      end
    end
  end

  describe 'when the config DSL defines an on_open_worktree callback' do
    it 'executes the callback with the worktree directory, after the branch has been pushed' do
      branch_name = 'feature/with-open-callback'
      worktree_dir = ".worktrees/#{branch_name.tr('/', '_')}"
      with_git_workspace(
        files: { 'test.txt' => "original\n" },
        remotes: { 'github' => 'git@github.com:owner/repo.git' }
      ) do
        File.write('.x_aeon_agents.rb', <<~CONFIG)
          on_open_worktree do |dir|
            XAeonAgents::Helpers.run_cmd "echo opened \#{dir}"
          end
        CONFIG
        # Load the config file, like the CLI does before running the agent
        XAeonAgents::Config.load

        mock_git_push
        opened_dirs = []
        stub_command(
          /echo/,
          stdout: proc do |cmd|
            opened_dirs << [cmd, git_pushes.size]
            ''
          end
        )

        described_class.new(session_id: nil).run(branch_name: branch_name)

        # The callback has been executed exactly once, with the worktree directory as parameter
        expect(opened_dirs).to eq [["echo opened #{worktree_dir}", 1]]

        # The callback has been executed after the branch has been pushed
        expect(git_pushes).to eq [['--set-upstream', 'github', branch_name]]

        # The worktree has been created as usual
        expect(Dir).to exist(worktree_dir)
        expect(Git.open(worktree_dir).current_branch).to eq branch_name
      end
    end
  end

  describe 'when the config DSL does not define an on_open_worktree callback' do
    it 'does not execute anything when the worktree is opened' do
      branch_name = 'feature/without-open-callback'
      worktree_dir = ".worktrees/#{branch_name.tr('/', '_')}"
      with_git_workspace(
        files: { 'test.txt' => "original\n" },
        remotes: { 'github' => 'git@github.com:owner/repo.git' }
      ) do
        mock_git_push
        executed_commands = []
        stub_command(
          /VSCodium/,
          stdout: proc do |cmd|
            executed_commands << cmd
            ''
          end
        )

        described_class.new(session_id: nil).run(branch_name: branch_name)

        # No command has been executed to open the worktree
        expect(executed_commands).to be_empty

        # The worktree has been created and pushed as usual
        expect(Dir).to exist(worktree_dir)
        expect(Git.open(worktree_dir).current_branch).to eq branch_name
        expect(git_pushes).to eq [['--set-upstream', 'github', branch_name]]
      end
    end
  end

  describe 'calling start_task twice on the same branch with an on_open_worktree callback' do
    it 'executes the callback every time the worktree is opened' do
      branch_name = 'feature/open-callback-idempotent'
      worktree_dir = ".worktrees/#{branch_name.tr('/', '_')}"
      with_git_workspace(
        files: { 'test.txt' => "original\n" },
        remotes: { 'github' => 'git@github.com:owner/repo.git' }
      ) do
        File.write('.x_aeon_agents.rb', <<~CONFIG)
          on_open_worktree do |dir|
            XAeonAgents::Helpers.run_cmd "echo opened \#{dir}"
          end
        CONFIG
        # Load the config file, like the CLI does before running the agent
        XAeonAgents::Config.load

        mock_git_push
        opened_dirs = []
        stub_command(
          /echo/,
          stdout: proc do |cmd|
            opened_dirs << cmd
            ''
          end
        )

        # First call: the worktree is freshly created
        described_class.new(session_id: nil).run(branch_name: branch_name)
        expect(opened_dirs.size).to eq 1

        # Second call: the worktree already exists
        described_class.new(session_id: nil).run(branch_name: branch_name)

        # The callback has been executed again for the existing worktree
        expect(opened_dirs).to eq [
          "echo opened #{worktree_dir}",
          "echo opened #{worktree_dir}"
        ]
      end
    end
  end
end
