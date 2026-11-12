require_relative 'shared_examples/common_behavior'
require_relative 'shared_examples/non_interactive'

describe XAeonAgents::Agents::DiffInterpreterAgent do
  it_behaves_like 'an agent with common behavior', described_class
  it_behaves_like 'an agent respecting the non-interactive mode', described_class
end
