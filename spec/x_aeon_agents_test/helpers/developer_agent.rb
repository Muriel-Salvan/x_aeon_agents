module XAeonAgentsTest
  module Helpers
    module DeveloperAgent
      # Stub the DeveloperAgent's #new and #run methods.
      #
      # DeveloperAgent inherits from ComposableAgents::Agent directly, so it is not covered by
      # stub_agent_run (which only stubs ComposableAgents::AiAgents::Agent and ComposableAgents::Cline::Agent).
      # This helper mocks it explicitly, capturing its run input artifacts for assertions in the test scenarios.
      def stub_developer_agent
        @developer_agent_run_calls = []
        allow(XAeonAgents::Agents::DeveloperAgent).to receive(:new)
          .and_wrap_original do |original, **kwargs|
            dev_instance = original.call(**kwargs)
            allow(dev_instance).to receive(:run) do |**run_kwargs|
              developer_agent_run_calls << { agent: dev_instance, kwargs: run_kwargs }
              {}
            end
            dev_instance
          end
      end

      # @return [Array<Hash{Symbol => Object}>] The list of DeveloperAgent#run calls, each hash having
      #   :agent (the DeveloperAgent instance whose run was called) and :kwargs (the keyword arguments
      #   passed to that run call) keys.
      attr_reader :developer_agent_run_calls
    end
  end
end
