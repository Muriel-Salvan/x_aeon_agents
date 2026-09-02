module XAeonAgentsTest
  module Stubs
    # Mixin prepended onto ComposableAgents::Agent to intercept agent instantiation during tests.
    # Because it is prepended on the base agent class, all agents (including orchestrators that
    # don't use AI frameworks) get their constructor call recorded, with the kwargs as computed by
    # the AgentDefaults mixin (ie. after application of the config DSL default kwargs).
    module AgentInstantiationSpy
      class << self
        # @return [Array<Hash>, nil] Collector for captured Agent.new calls, or nil if not wired
        attr_accessor :instantiations
      end

      # Intercept Agent.new to capture constructor arguments, then let
      # the normal initialization chain proceed.
      def initialize(*args, **kwargs, &)
        (AgentInstantiationSpy.instantiations || []) << {
          agent: self,
          args: args.map(&:clone),
          kwargs: kwargs.to_h { |k, v| [k, v.clone] }
        }
        super
      end
    end
  end
end
