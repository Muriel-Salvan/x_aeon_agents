require 'cleanroom'

module XAeonAgents
  # Cleanroom-based DSL exposed by the optional .x_aeon_agents.rb config file.
  class ConfigDsl
    include Cleanroom

    # Set the debug mode.
    #
    # Parameters::
    # * *value* (Boolean): The debug mode to set
    def debug(value)
      Config.debug = value
    end

    expose :debug

    # Define the steps to execute in a fresh worktree to install the project's dependencies.
    # The given block is stored and evaluated only when a fresh worktree is created by the
    # start-task command, with the current directory set to the worktree. If this method is
    # not used in the config, no setup step is executed.
    #
    # Parameters::
    # * *steps_proc* (Proc): Code executing the setup steps (can use XAeonAgents::Helpers.run_cmd to run commands)
    def setup_project(&steps_proc)
      Config.register_setup_project_proc(steps_proc)
    end

    expose :setup_project

    # Define the callback to execute when a worktree has been opened by the start-task command.
    # The given block is stored and evaluated every time a worktree is opened (freshly created
    # or already existing), after the branch has been pushed to the remote. It is given the
    # worktree's directory as parameter. If this method is not used in the config, nothing is
    # executed when a worktree is opened.
    #
    # Parameters::
    # * *callback_proc* (Proc): Code executing the callback, given the worktree's directory
    #   (can use XAeonAgents::Helpers.run_cmd to run commands)
    def on_open_worktree(&callback_proc)
      Config.register_open_worktree_proc(callback_proc)
    end

    expose :on_open_worktree

    # Automatically expose a method per known secret name, allowing the config file
    # to define the code to retrieve this secret. The given block is stored as a Proc
    # and evaluated lazily only when the secret is needed.
    Config::KNOWN_SECRETS.each do |secret_name|
      # Define the code to retrieve a secret.
      #
      # Parameters::
      # * *retrieval_proc* (Proc): Code returning the secret value when evaluated
      define_method(secret_name) do |&retrieval_proc|
        Config.register_secret_proc(secret_name, retrieval_proc)
      end

      expose secret_name
    end
  end
end
