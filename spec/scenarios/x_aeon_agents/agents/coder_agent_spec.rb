require_relative 'shared_examples/artifact_types'
require_relative 'shared_examples/common_behavior'
require_relative 'shared_examples/repository_scope'
require_relative 'shared_examples/non_interactive'

describe XAeonAgents::Agents::CoderAgent do
  it_behaves_like 'an agent with common behavior', described_class
  it_behaves_like 'an agent respecting the non-interactive mode', described_class
  it_behaves_like 'an agent scoped to the current repository', described_class, writable: true
  it_behaves_like 'an agent declaring artifact types', described_class, input_types: { plan: :markdown }
end
