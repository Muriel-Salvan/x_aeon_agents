require_relative 'shared_examples/common_behavior'

describe XAeonAgents::Agents::OneLineCodeDiffSummarizerAgent do
  it_behaves_like 'an agent with common behavior', described_class
end
