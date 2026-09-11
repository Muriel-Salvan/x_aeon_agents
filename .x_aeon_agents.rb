setup_project { system 'bundle install' }

test_project_cmd 'bundle exec rspec --format=documentation'

project_skills = %w[
  applying-ruby-conventions
  applying-test-conventions
  enforcing-project-rules
]
project_doc_skills = %w[
  updating-doc
]

readme_agents = %i[
  AboutAnalyzerAgent
  ContributingAgent
  DevelopmentAgent
  DocumentationAgent
  FeaturesAgent
  HowItWorksAgent
  LicenseAgent
  PublicApiAgent
  QuickStartAgent
  RequirementsAgent
]
rw_agents = %i[
  CoderAgent
  TesterAgent
  DocumenterAgent
] + readme_agents
rw_doc_agents = %i[
  DocumenterAgent
]
ro_agents = %i[
  FeedbackAnalystAgent
  PlanGeneratorAgent
  ReviewResponderAgent
]

(ro_agents + rw_agents).each do |agent|
  configure_agent(agent) { { skills: project_skills } }
end

rw_doc_agents.each do |agent|
  configure_agent(agent) do |agent_config|
    { skills: (agent_config[:skills] || []) + project_doc_skills }
  end
end
