require_relative 'shared_examples/artifact_types'
require_relative 'shared_examples/artifacts_access'
require_relative 'shared_examples/common_behavior'
require_relative 'shared_examples/repository_scope'

describe XAeonAgents::Agents::TesterAgent do
  it_behaves_like 'an agent with common behavior', described_class
  it_behaves_like 'an agent scoped to the current repository', described_class, writable: true
  it_behaves_like 'an agent allowed to write its output artifacts', described_class, %i[plan_modifications]
  it_behaves_like 'an agent declaring artifact types', described_class,
    input_types: {
      requirements: :markdown,
      plan: :markdown,
      files_diffs: :text,
      tests_output: :text,
      tests_cmd: :text
    },
    output_types: { plan_modifications: :markdown }
end
