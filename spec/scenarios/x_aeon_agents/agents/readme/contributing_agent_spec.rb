require_relative '../shared_examples/common_behavior'
require_relative '../shared_examples/repository_scope'

describe XAeonAgents::Agents::Readme::ContributingAgent do
  it_behaves_like 'an agent with common behavior', described_class
  it_behaves_like 'an agent scoped to the current repository', described_class
end
