# [v1.0.28](https://github.com/Muriel-Salvan/x_aeon_agents/compare/v1.0.27...v1.0.28) (2026-07-14 17:05:02)

### Patches

* [test(helpers): convert temporary test directory path to absolute](https://github.com/Muriel-Salvan/x_aeon_agents/commit/1de480ef42f8046bd597eb513d120cbc1bde6067)
* [fix(cli): add missing period to revision prompts in spec](https://github.com/Muriel-Salvan/x_aeon_agents/commit/59704340bb26401aff6087c5509f739c02c53b12)
* [refactor(planner-agent): replace ternary with if-else for diffs](https://github.com/Muriel-Salvan/x_aeon_agents/commit/5d2e0ff1ae12802a4d17e8be5c0a0ce7ee08f9fb)
* [test: mock git remotes to isolate README badge generation](https://github.com/Muriel-Salvan/x_aeon_agents/commit/15dbc53613872c3daf2b7a41e25f7a97fab61462)
* [fix(planner): normalize trailing newlines in plan diff generation](https://github.com/Muriel-Salvan/x_aeon_agents/commit/d635809fc76c698df64cc9acd8cd443a75b86127)
* [chore: make skill scripts executable and remove blank line](https://github.com/Muriel-Salvan/x_aeon_agents/commit/2b1ae57a5a6116acaae1c02da321964f66d72040)
* [docs: expand README with setup, API, and contribution docs](https://github.com/Muriel-Salvan/x_aeon_agents/commit/2974c179e83868dc88d2ddd9ad271c889b287149)
* [test: use test-free-complex models in specs and tweak docs](https://github.com/Muriel-Salvan/x_aeon_agents/commit/06b45d0e4fc9c83007c18cb235b166f614ce4c93)
* [feat: add AgentOptions class to centralize agent configurations](https://github.com/Muriel-Salvan/x_aeon_agents/commit/37fee0499a76fa6ef2cda7ceac011e6556bf7000)
* [refactor: make GenHelpers methods private and re-enable MarshalLoad cop](https://github.com/Muriel-Salvan/x_aeon_agents/commit/e26bcb31016a5431fba4a2f6ef25f44312ed1422)
* [refactor(config): reorganize API groups and add config specs](https://github.com/Muriel-Salvan/x_aeon_agents/commit/4b191da610d1aadf7eb783003ecaa208ecc0657b)
* [test(cli): Split implement_issue test scenarios](https://github.com/Muriel-Salvan/x_aeon_agents/commit/333c1b5b9ccfbc4ffc7413655847298716587dcc)
* [test(cli): add tests for issue header leveling, labels, comments](https://github.com/Muriel-Salvan/x_aeon_agents/commit/0cf3175f73b5de792133346e2b860b615c9d7c58)
* [refactor(agents): dynamically build issue section and add CLI tests](https://github.com/Muriel-Salvan/x_aeon_agents/commit/af3b1baf7949223db94fa29c233d3088f5ec94e3)
* [feat(review_resolver): auto-detect PR number from current branch](https://github.com/Muriel-Salvan/x_aeon_agents/commit/426f404ad3cdb49c0168815bd27d2869851b1b10)
* [refactor(agents): use JSON artifacts for PR conversations](https://github.com/Muriel-Salvan/x_aeon_agents/commit/646174d8dc0f4ce984d40c8d9daa70ed80cd5ffb)
* [fix(task-starter): raise error for invalid existing worktree dir](https://github.com/Muriel-Salvan/x_aeon_agents/commit/c812df07e35d62d7ba40ab196091aa267c552e92)
* [feat(cli): make start-task idempotent and add --branch option](https://github.com/Muriel-Salvan/x_aeon_agents/commit/40f3a4af28a8249742efa58a5b387ba712c47b75)
* [refactor: use github remote helper and add start_task tests](https://github.com/Muriel-Salvan/x_aeon_agents/commit/1df59c4d3ed871ac3550527afe81aa7652eec76b)
* [refactor(agents): use Helpers for git worktree and run_cmd](https://github.com/Muriel-Salvan/x_aeon_agents/commit/79545f7d1662b6a5e7bb355973a7111a4b3b5027)
* [fix(pr): use plan generator agent and skip initial user prompt](https://github.com/Muriel-Salvan/x_aeon_agents/commit/f55e34d536fd3c28f8c9438d937bc326ecdbb329)
* [feat(developer_agent): add coder and tester as authors for PR](https://github.com/Muriel-Salvan/x_aeon_agents/commit/8f06c8412e4eba2cbc19a359bbc4780d0d3d5a3b)
* [refactor: extract planner_agent variable for clarity](https://github.com/Muriel-Salvan/x_aeon_agents/commit/588c73e5455a5e019c607729eafb3bd9f7f9c0d4)
* [test: split create-pr specs](https://github.com/Muriel-Salvan/x_aeon_agents/commit/c61c46490259cddf8f52632bb06d6a741427c376)
* [test: refactor GitDiffInterpreterAgent stubbing and add existing PR tests](https://github.com/Muriel-Salvan/x_aeon_agents/commit/1e801bd8a7269da245eeff7a6bf3890d8848f566)
* [test(cli): add spec for create_pr command](https://github.com/Muriel-Salvan/x_aeon_agents/commit/c82b32f185264c03d55c67afd1874538c9518f11)
* [test: clear GitHub helper caches in spec_helper before each test](https://github.com/Muriel-Salvan/x_aeon_agents/commit/4e8dfcb83ba8a860d8143dd6a7bf68d3e084b5ad)
* [refactor: replace system calls with git helper methods](https://github.com/Muriel-Salvan/x_aeon_agents/commit/dabb6eddd7dd0c8efa16da013ca44f970c77d757)
* [refactor(issue_implementer): run developer agent via step_agent](https://github.com/Muriel-Salvan/x_aeon_agents/commit/23e1ca426651f6f9c1a01838dce54f75551ab76c)
* [test(cli): add spec for session ID reuse and relax RSpec expectation limit](https://github.com/Muriel-Salvan/x_aeon_agents/commit/3bf8adb9f4c7fc20284ccd15d04b78ec4af04aa4)
* [test(cli): add spec for implement command with commits](https://github.com/Muriel-Salvan/x_aeon_agents/commit/ab636a0db2a0cf5dc7bb94dc4721f7588aebf499)
* [test(cli): add spec for implement command with plan review](https://github.com/Muriel-Salvan/x_aeon_agents/commit/479892adc7cf7ec47cae1f4f67da7fde78cb0b74)
* [test(helpers): allow array of stdin responses in mock helper](https://github.com/Muriel-Salvan/x_aeon_agents/commit/39f359eac7621b03573ae5c16d07a8efd9b5110d)
* [test: update specs to align with agent interface changes](https://github.com/Muriel-Salvan/x_aeon_agents/commit/d4ea7c5cb124caf6d18a0318928a69eab3a66b0a)
* [fix: include committer agent for pull requests and improve PR creation](https://github.com/Muriel-Salvan/x_aeon_agents/commit/9e097a1bfea1152f76978876c74c366ccee7de2a)
* [test(cli): add tests for file diffs and Markdown header alignment](https://github.com/Muriel-Salvan/x_aeon_agents/commit/455ad8257bd4510708d864e4d34ab844fb319fa8)
* [test: add test coverage for Coder and Documenter agents in CLI implement](https://github.com/Muriel-Salvan/x_aeon_agents/commit/decbba6932538cf900d2a8a7806507eaa7489554)
* [fix: properly integrate plan modifications with markdown alignment](https://github.com/Muriel-Salvan/x_aeon_agents/commit/a1275811c3e4039ea03558bb88ac86c97145a5c2)
* [test(cli): add implement scenario spec and bump rubocop example length](https://github.com/Muriel-Salvan/x_aeon_agents/commit/996695c8d661cb34dea3e913192b72a896f13ebe)
* [chore: add secret_string require and configure test API keys](https://github.com/Muriel-Salvan/x_aeon_agents/commit/ae3acd601861ceab93ecd3f0de1a243fdb40ce0c)
* [test: add find_run_calls_for helper and update interpret-diffs test](https://github.com/Muriel-Salvan/x_aeon_agents/commit/f8f273a48f716c7e37508f6ac67753cd38e96c0e)
* [refactor(planner): extract plan_generator_agent and update contracts](https://github.com/Muriel-Salvan/x_aeon_agents/commit/e431ebe93ab2794b20d2a0e7d175b31eb835912c)
* [feat: allow stub_command to accept static values for stdout, stderr, exit_status](https://github.com/Muriel-Salvan/x_aeon_agents/commit/5500eba0ee3c09fdcfb75a77323a56e638dee772)
* [refactor: extract stub_command helper for Open3 stubbing](https://github.com/Muriel-Salvan/x_aeon_agents/commit/190635ae53c38969e950823910140371aa056885)
* [feat(cli): add --stage option to control commit staging strategy](https://github.com/Muriel-Salvan/x_aeon_agents/commit/a27d4ba815698232739428eb033623f53a5e0fb2)
* [test(cli): add RSpec test scenarios for the commit command](https://github.com/Muriel-Salvan/x_aeon_agents/commit/1a93cb02fbb64ad66b2e33274bb229cf0309d85f)
* [test: add review_content helper to stub interactive review flow](https://github.com/Muriel-Salvan/x_aeon_agents/commit/66fbf06cd96fdc3cd2d275fa3b003d5c01598257)
* [refactor(git_diff_interpreter_agent): memoize agent creation](https://github.com/Muriel-Salvan/x_aeon_agents/commit/1c5b33ffa45e7de7fe7d3f16b3397ec9e60eba46)
* [test: update tmp_path spec to compare with absolute path](https://github.com/Muriel-Salvan/x_aeon_agents/commit/c85e01d9a06aaee41cfb9207bc3c0d3c7c3e56b1)
* [refactor: extract git test helpers into dedicated module](https://github.com/Muriel-Salvan/x_aeon_agents/commit/7e956c27addffcb9135f94d02007ba4b5127b90d)
* [test(cli): split specs for interpret-diffs](https://github.com/Muriel-Salvan/x_aeon_agents/commit/50c18dcb49268c5884fa3cf0cd0163c115070436)
* [refactor(git_diff_interpreter): use step_agent for agent orchestration + Added full tests](https://github.com/Muriel-Salvan/x_aeon_agents/commit/8ce0f4566768a171d40558087bfb7070258c5685)
* [test: replace before hook with around hook for proper cleanup](https://github.com/Muriel-Salvan/x_aeon_agents/commit/c3dcda1386a6c872678747a0b43ef50d1f0bb3bd)
* [test(cli): Split generate_readme specs in various scenario files](https://github.com/Muriel-Salvan/x_aeon_agents/commit/8f8990811daa7c2f674598c411a6819ca9fb36dc)
* [test(cli): remove redundant setup from generate_readme spec](https://github.com/Muriel-Salvan/x_aeon_agents/commit/1d3a17be0ed3cea300d69a0aedf7f9536eb9e9d2)
* [feat(readme_generator): allow custom README file path](https://github.com/Muriel-Salvan/x_aeon_agents/commit/701802f6f8066efb43074ffd8f919b4795fde676)
* [refactor(helpers): simplify run_cmd and fix output joining](https://github.com/Muriel-Salvan/x_aeon_agents/commit/d6dc1b568bad6c48f039404df9dce9d0e780e9c3)
* [test(helpers): add TEST_DEBUG mode and consolidate includes](https://github.com/Muriel-Salvan/x_aeon_agents/commit/5e6897760e2cbedaba2ff8b27070bbef0e8ecc7e)
* [test(cli): append optional default_cli_args in test helper](https://github.com/Muriel-Salvan/x_aeon_agents/commit/df2ca04583a38b9f7d27f0fd8bf69567cd50a378)
* [refactor: use Config.data_dir for sessions, tmp and review paths](https://github.com/Muriel-Salvan/x_aeon_agents/commit/5b18bc43bd2d736a66b6d4f0c6a172ab8208075b)
* [refactor(test-stub): replace static conversation with stub_handler lambda](https://github.com/Muriel-Salvan/x_aeon_agents/commit/07b23fbf30e022bcc0d5af098b7b79a5956bbc76)
* [refactor(test): simplify stub_agent_run helper](https://github.com/Muriel-Salvan/x_aeon_agents/commit/931102cf285b68e280220d22b3bffa08b9db55c7)
* [test: add specs for generate-readme with all sections disabled](https://github.com/Muriel-Salvan/x_aeon_agents/commit/d6f7abac82ccf5f584466cfcf94c1f352cfb683f)
* [refactor(test): replace AiAgentsStub with PromptAgentsStub](https://github.com/Muriel-Salvan/x_aeon_agents/commit/ed8aedf7a8b0fed33b882249675bcd51905c11fd)
* [test: add prompt CLI tests and reorganize test helpers](https://github.com/Muriel-Salvan/x_aeon_agents/commit/5d91b6e80a064b9d83bae885c2be5736e748200f)
* [test(skills): reorganize generation specs and add coverage for filtering and output dir](https://github.com/Muriel-Salvan/x_aeon_agents/commit/0427a3520d534eff993cdd2506cf14d50ca5268f)
* [feat(cli): add --skill option to filter generated skills](https://github.com/Muriel-Salvan/x_aeon_agents/commit/ac6c64b9a826fa610e24ce73118a5488493ae3af)
* [refactor(cli specs): simplify generate_skills quality and functional specs](https://github.com/Muriel-Salvan/x_aeon_agents/commit/6952ba138710c8138ccfd199d032664c492e5173)
* [fix: correct github_repo extraction and add specs for agent methods](https://github.com/Muriel-Salvan/x_aeon_agents/commit/7d113ff910ca69835a41e54569f3bb2b3e630b8c)
* [chore: relax RuboCop complexity threshold and fix string alignment](https://github.com/Muriel-Salvan/x_aeon_agents/commit/fc0b2842f3763482b16ba2044d5459153d1c8bd2)
* [refactor: relax Rubocop metrics and enforce string concatenation style](https://github.com/Muriel-Salvan/x_aeon_agents/commit/5c16804a0e4512e8dcec0b90451f154b5454cdaf)
* [refactor: improve code style, readability, and robustness](https://github.com/Muriel-Salvan/x_aeon_agents/commit/a996b25689ed7d39aa250bca8b2b104fe2c4d1d0)
* [docs: add YARD documentation to agents and CLI commands](https://github.com/Muriel-Salvan/x_aeon_agents/commit/fe3cdc5037851e204361a765439504a376f9c840)
* [docs: standardize YARD documentation and formatting](https://github.com/Muriel-Salvan/x_aeon_agents/commit/27114f11c465ada2a3374589b37c5eaa17d30990)
* [refactor: move gh_comments.gql into agents directory](https://github.com/Muriel-Salvan/x_aeon_agents/commit/0194c9f3c8724446af4654a4e82526f3b85b9570)
* [docs: revamp README with badges and add TOC generation debug log](https://github.com/Muriel-Salvan/x_aeon_agents/commit/2e6f7e9159e27c8768cec1d4725cac6a1f99c9fa)
* [feat(cli): add debug option and update command examples](https://github.com/Muriel-Salvan/x_aeon_agents/commit/de7de3ce115dac7e3f29a9f48ee664376262cbab)
* [refactor: use SecretString for secret API key management](https://github.com/Muriel-Salvan/x_aeon_agents/commit/1759ec625d59535fc280c200057d17727e96d269)
* [refactor: extract CLI implementation from bin/xaa into module](https://github.com/Muriel-Salvan/x_aeon_agents/commit/76e46030aecbdd00d72348b1205fa61916530e7c)
* [feat(agents): pass session_id to agent constructors](https://github.com/Muriel-Salvan/x_aeon_agents/commit/1be4f2cae7cce114c5a83924e3836f860dc840e7)
* [refactor: replace inline procedures with agent calls in CLI](https://github.com/Muriel-Salvan/x_aeon_agents/commit/c7360deb83977d53fc9f79087da9ecf9ed91ebf9)
* [refactor(cli): centralize session_id as a global class option](https://github.com/Muriel-Salvan/x_aeon_agents/commit/dfa54e3e56e1ef2eb5acb842a1f82120ab839397)
* [test(packaging): update packaging specs for x_aeon_agents rename](https://github.com/Muriel-Salvan/x_aeon_agents/commit/38b10b8ada154c4e38ea7872e714dcf67f64f1d6)
* [feat: add unified CLI tool `xaa` and replace generate_skills](https://github.com/Muriel-Salvan/x_aeon_agents/commit/8ccca188af05289ed1c901e70e10c2aaf30fdfd8)
* [chore: rename repository references from x_aeon_agents_skills to x_aeon_agents](https://github.com/Muriel-Salvan/x_aeon_agents/commit/65ff71a3ab945ad4f143a51bdefdf1fe869b38b0)
* [refactor(bin): migrate agent execution to dedicated classes with session_id](https://github.com/Muriel-Salvan/x_aeon_agents/commit/d061dadacadd3b8e3e6100e2fa4e80dfc8b1a175)
* [refactor: streamline session ID generation and mixin prepending in AgentDefaults](https://github.com/Muriel-Salvan/x_aeon_agents/commit/8874080a2cc82aff15ca24d624016223297e361c)
* [feat(readme_generator): add gem download badge and update badge links](https://github.com/Muriel-Salvan/x_aeon_agents/commit/cccb706efa7fbaf9dd4774b04c891a96e98ef6ca)
* [test: add documentation and packaging specs, code coverage setup](https://github.com/Muriel-Salvan/x_aeon_agents/commit/9afcaba5b2ef1707a75da581fa5d6476512e4b5f)
* [refactor(readme generator): use doctoc for TOC, switch sections to hashes](https://github.com/Muriel-Salvan/x_aeon_agents/commit/b468c91fb678a3871979b837a7cdd7bb29873c56)
* [feat(agents): add section selection options to generate_readme](https://github.com/Muriel-Salvan/x_aeon_agents/commit/de561b92f86d5ebb58c2ade5715f85be339f6c18)
* [feat(readme-generator): strip single top-level grouping header from section content](https://github.com/Muriel-Salvan/x_aeon_agents/commit/9d4d9952eb3b349a56057b95f3555b3a06342175)
* [feat: add fine-grained section control to readme generator agent](https://github.com/Muriel-Salvan/x_aeon_agents/commit/a1d448c53d7236d8f4ee70c5ac32e9384b1c9bdc)
* [refactor(agents): enhance output artifact contracts with type and add run_id to readme generation](https://github.com/Muriel-Salvan/x_aeon_agents/commit/fcf6e6b2ae297fe226745a472e6d674d6bc0e886)
* [refactor: standardize JSON serialization using JSON.dump](https://github.com/Muriel-Salvan/x_aeon_agents/commit/61c013054533f1b15c71689620e1fe1199cb42c2)
* [fix: add GitHub repo validation and nil-safe helpers](https://github.com/Muriel-Salvan/x_aeon_agents/commit/d5f3ead5da386a11faf9bfdd784f54a5eec7aa5e)
* [refactor: reorganize requires and remove unused gems](https://github.com/Muriel-Salvan/x_aeon_agents/commit/b55ce8ac6baa5cfe1e768be7e3ea3c57a692a00c)
* [chore: remove Cline API key configuration from RubyLLM setup](https://github.com/Muriel-Salvan/x_aeon_agents/commit/e48c01f879d154d3f3abc20119ad0a6c8a8b82db)
* [feat(agents): add generate_readme agent and specialized README section agents](https://github.com/Muriel-Salvan/x_aeon_agents/commit/41bd7635b9666b2e6e0c1e58b2c207971c5709af)
* [refactor: clean up unused methods, classes and helpers now that composable_agents Rubygem is used for all agents](https://github.com/Muriel-Salvan/x_aeon_agents/commit/198617e5ff5e3cbb46c0400d03cd4878fdb5af7e)

# [v1.0.27](https://github.com/Muriel-Salvan/x_aeon_agents/compare/v1.0.26...v1.0.27) (2026-06-25 15:49:37)

### Patches

* [feat: add start_task script to create worktree from branch](https://github.com/Muriel-Salvan/x_aeon_agents/commit/ed8e8d7ac148c0edd9359ef35587f0c9de24a1a3)
* [refactor(agents): replace direct implement_requirements with DeveloperAgent step](https://github.com/Muriel-Salvan/x_aeon_agents/commit/46b4a2e525f8bce4f3eb234a8be39e301675c0e3)

# [v1.0.26](https://github.com/Muriel-Salvan/x_aeon_agents/compare/v1.0.25...v1.0.26) (2026-06-25 15:16:05)

### Patches

* [chore: remove unused debug gem from Gemfile](https://github.com/Muriel-Salvan/x_aeon_agents/commit/f838ca06e4676f266cf85dfe59d3986c4c05422d)
* [refactor(agents): simplify return values and update free model](https://github.com/Muriel-Salvan/x_aeon_agents/commit/cd21ffa9815f2db979bbf8e02ee160e7ba35fc12)

# [v1.0.25](https://github.com/Muriel-Salvan/x_aeon_agents/compare/v1.0.24...v1.0.25) (2026-06-25 14:48:43)

### Patches

* [feat: switch free_simple model to cohere/north-mini-code](https://github.com/Muriel-Salvan/x_aeon_agents/commit/83c12a2baa9d815c5fa73b8895142c995de47a7c)

# [v1.0.24](https://github.com/Muriel-Salvan/x_aeon_agents/compare/v1.0.23...v1.0.24) (2026-06-25 14:15:52)

### Patches

* [refactor(agents): Migrate to structured agent params and artifact refs](https://github.com/Muriel-Salvan/x_aeon_agents/commit/d28770dbd574c41d61c3dc0a67304de4d07eb0b3)

# [v1.0.23](https://github.com/Muriel-Salvan/x_aeon_agents/compare/v1.0.22...v1.0.23) (2026-06-25 14:05:41)

### Patches

* [refactor(agents): centralize artifact contracts via ArtifactContract mixin](https://github.com/Muriel-Salvan/x_aeon_agents/commit/617bb3d3df830900dc96b1912d371f201a87787e)

# [v1.0.22](https://github.com/Muriel-Salvan/x_aeon_agents/compare/v1.0.21...v1.0.22) (2026-06-25 13:23:28)

### Patches

* [feat(review_resolver): propagate run_id to implement_requirements](https://github.com/Muriel-Salvan/x_aeon_agents/commit/137812efa2eba087bdfe2d7b1263e06ec4e0eb71)

# [v1.0.21](https://github.com/Muriel-Salvan/x_aeon_agents/compare/v1.0.20...v1.0.21) (2026-06-25 13:18:17)

### Patches

* [docs: add note about .x-aeon_agents directory placement](https://github.com/Muriel-Salvan/x_aeon_agents/commit/5ed025ec848ae11ef85b67775dede57f598fbea5)
* [refactor(agents): standardize initialization parameters across agents](https://github.com/Muriel-Salvan/x_aeon_agents/commit/263796ab03e32c5ca713ba02818692c66a97d68e)

# [v1.0.20](https://github.com/Muriel-Salvan/x_aeon_agents/compare/v1.0.19...v1.0.20) (2026-06-25 12:46:28)

### Patches

* [refactor: use agent.full_name for consistent identification](https://github.com/Muriel-Salvan/x_aeon_agents/commit/a727dea1002e37a7c013780610a75802349d1eec)
* [refactor(agents): replace JSON.pretty_generate with JSON.dump](https://github.com/Muriel-Salvan/x_aeon_agents/commit/3614db41bd5197533bef4a95d5fa3b82a5c7fa5a)

# [v1.0.19](https://github.com/Muriel-Salvan/x_aeon_agents/compare/v1.0.18...v1.0.19) (2026-06-24 14:54:52)

### Patches

* [refactor: Use composable_agents for agents resolving PR feedback](https://github.com/Muriel-Salvan/x_aeon_agents/commit/d764698d928868c1ded065d3c040972d9ac76e71)
* [feat: enhance CoderAgent with session defaults and updated prompts](https://github.com/Muriel-Salvan/x_aeon_agents/commit/bef9834d3f4b4d8e7fcc28a89bc245967b84edfe)
* [fix(config): Enable COMPOSABLE_AGENTS_DEBUG when debug mode is activated](https://github.com/Muriel-Salvan/x_aeon_agents/commit/3e2b88954d489741f49b8f6c7a644ee52415fe58)
* [feat(bin): Rewrite implement_requirements with Thor CLI & add new option flags](https://github.com/Muriel-Salvan/x_aeon_agents/commit/1dd1039018744b52cfb25e7d8346ab661d8a8464)
* [refactor: Extract implement_requirements workflow into dedicated DeveloperAgent](https://github.com/Muriel-Salvan/x_aeon_agents/commit/791791012e286c1f6f9117ae428856f596f75697)
* [refactor(agents): Use dedicated ExecutorAgent for simple task execution](https://github.com/Muriel-Salvan/x_aeon_agents/commit/39fcc653918b395f4e09fdbe2f2160482990db17)
* [feat(committer-agent): add configurable staging, co-authors and review workflow](https://github.com/Muriel-Salvan/x_aeon_agents/commit/90f57abd303a2445589763c128b6daa407ac8b3e)
* [refactor: Move configuration from Agents to dedicated Configuration module](https://github.com/Muriel-Salvan/x_aeon_agents/commit/c668aafed6677efc7fd7ddab445aefc569ff1ab9)
* [chore: adjust rubocop linter rules and update project TODO list](https://github.com/Muriel-Salvan/x_aeon_agents/commit/59f7fdd89952496b51360a526ec8c8bc68bb7d4f)
* [Refactor: introduce GitDiffInterpreterAgent pipeline for structured git diff interpretation and one-line summarization](https://github.com/Muriel-Salvan/x_aeon_agents/commit/a2c087d0785aa85385f34a508e3301f4169b54ba)
* [feat(xAeonAgentsSkills): replace runner abstraction with explicit agent instantiation and structured response parsing](https://github.com/Muriel-Salvan/x_aeon_agents/commit/4378bae59a8d5d0a92952c635faa878fb23836a7)
* [Refactor configuration with keys_from_launcher helper for DRY API key management and environment-based debug mode](https://github.com/Muriel-Salvan/x_aeon_agents/commit/3211b96b7fcb3ee3f873d7ed99f574eccd450c3c)
* [refactor: use keyword args in committer_agent and optimize deep_merge helper](https://github.com/Muriel-Salvan/x_aeon_agents/commit/dbe391f93575449f126eb3fc71167f3f4a159c02)
* [feat(models, agents): introduce flexible parameterization for AI model configuration](https://github.com/Muriel-Salvan/x_aeon_agents/commit/38d6b85da48cfef82e29b25defc36e58e1f6df3b)
* [feat(xaeon_agents_skills): simplify CommitterAgent namespace reference in commit method](https://github.com/Muriel-Salvan/x_aeon_agents/commit/f3dc45e73a1a768374ecfc846144acdec11b2a37)
* [feat(diff-interpreter, one-line-summarizer): extract contract methods for input/output artifacts](https://github.com/Muriel-Salvan/x_aeon_agents/commit/5fa9eb18e0ce7ba882f19e4aec55d5a8f3a06bca)
* [refactor: Standardize project naming, update imports, CI and auth config](https://github.com/Muriel-Salvan/x_aeon_agents/commit/51b6003169a9d069d7e57c95ef658a997fcf3315)
* [chore: Add initial RuboCop configuration with rubocop-rspec linting plugin](https://github.com/Muriel-Salvan/x_aeon_agents/commit/2bcdbac79cff907ec0d1b98b198078ac52920322)
* [chore(deps): Update ai-agents to ~>0.10 stable, remove github fork override](https://github.com/Muriel-Salvan/x_aeon_agents/commit/ef04a4badf6c1b02406e0221afc5474f9fb05e6c)
* [refactor: Update agent runner impl, default LLM model, add rubocop dev dep](https://github.com/Muriel-Salvan/x_aeon_agents/commit/4e327d8e44526c5e7d2538e3e4ab19480546982f)

# [v1.0.18](https://github.com/Muriel-Salvan/x-aeon_agents/compare/v1.0.17...v1.0.18) (2026-04-02 18:29:45)

## Global changes
### Patches

* [docs: add Cline rubygem creation task to project TODO list](https://github.com/Muriel-Salvan/x-aeon_agents/commit/f3ee3306dc8c08ca4406835755ba8f22f4218f2d)
* [build(deps): update ai-agents gem to use GitHub fork branch](https://github.com/Muriel-Salvan/x-aeon_agents/commit/b8b7e2b8be84b4e618e7b563a16ae5e3af457ba2)
* [fix: resolve initialization order, add nil-safety, and fix provider namespacing](https://github.com/Muriel-Salvan/x-aeon_agents/commit/4a4562069596445b1d20fedea8e76e32475c2915)
* [feat(provider): namespace Cline CLI models with `clinecli/` prefix to prevent model confusion](https://github.com/Muriel-Salvan/x-aeon_agents/commit/f345d9726699f355351e0b70f4f1e8e4f73f96c9)
* [feat(commit): add interactive commit workflow with diff interpreter agent and Launchy review](https://github.com/Muriel-Salvan/x-aeon_agents/commit/8f7e7b2a1c5fb8228505da3f4bba0f89cbae3de4)
* [feat(cline_cli): add token usage tracking and cost reporting](https://github.com/Muriel-Salvan/x-aeon_agents/commit/8097d56c553cbee9ad4400f5f87398c741711796)
* [feat(cline): add model caching, usage metrics, and tag parsing](https://github.com/Muriel-Salvan/x-aeon_agents/commit/a383bd29edc8a791451346aa9a469cda82f95c07)
* [Add refresh! to register Cline CLI provider](https://github.com/Muriel-Salvan/x-aeon_agents/commit/e33c2a4b6e6e73fa83e36a62413017abbd5e29b7)
* [Remove Cline provider and use Cline CLI instead](https://github.com/Muriel-Salvan/x-aeon_agents/commit/b8c6b5a161c03b50bd49499b15e8c89230ff6a71)
* [Update gemspec to include new dependencies and remove local gem references](https://github.com/Muriel-Salvan/x-aeon_agents/commit/ee931c20f813838d3d059bfcc0bd283a9a7929cc)
* [feat: Add automated Pull Request comment handling system with GitHub API integration](https://github.com/Muriel-Salvan/x-aeon_agents/commit/629ddba789ef402797cd51715ae249a5e757c5cb)
* [refactor: replace hardcoded model registration with dynamic Cline model discovery](https://github.com/Muriel-Salvan/x-aeon_agents/commit/3d790e72542744fdefaccdf261630786f433fde6)
* [refactor(cline): move private methods to proper section](https://github.com/Muriel-Salvan/x-aeon_agents/commit/f28eb27a4d2f4bdf12cdb006e43ed9bd22c2979d)
* [refactor: extract one-lining method for consistent text formatting](https://github.com/Muriel-Salvan/x-aeon_agents/commit/e5b933b0a91bcbccbb2d04cd94ea71d11c3a536e)
* [refactor: improve markdown formatting in PR generation](https://github.com/Muriel-Salvan/x-aeon_agents/commit/9b0c110abe93bad377d1edddb374245384c7737c)
* [refactor: rename 'code modifications' to 'files modifications' in diff interpreter agent](https://github.com/Muriel-Salvan/x-aeon_agents/commit/248f367c6e88c15612899cf58fe874e7d1902d7e)
* [refactor: simplify documentation agent instructions for clarity](https://github.com/Muriel-Salvan/x-aeon_agents/commit/44db9eb4ae391db9ebf13314b8df181264954a21)
* [feat: enhance GitHub issue implementation with improved markdown handling](https://github.com/Muriel-Salvan/x-aeon_agents/commit/4f4476c2f96ebdccd36d61de62e044ab15f6cc60)
* [refactor: simplify implement_github_issue method and improve code organization](https://github.com/Muriel-Salvan/x-aeon_agents/commit/72b9871a5025695fe82294a2adf23ca6d9116a2d)
* [feat: add address_pull_request_comments script and improve change intent description](https://github.com/Muriel-Salvan/x-aeon_agents/commit/10d453a8d2917410346639d593e84c955ce76d35)
* [refactor: simplify agent instructions for file change analysis](https://github.com/Muriel-Salvan/x-aeon_agents/commit/f94b4649b8cb931a4b85f823cd13531f1ee558f6)
* [feat: enhance diff interpreter agent objective with detailed goals](https://github.com/Muriel-Salvan/x-aeon_agents/commit/30cdf6d4dddda7a89aced44c4d23b1a6340f9d34)
* [feat(agents): simplify commit message generation instructions](https://github.com/Muriel-Salvan/x-aeon_agents/commit/ef63dfa4875b39068f26845cf6d4d20535a34b9f)
* [refactor: simplify user feedback artifact generation](https://github.com/Muriel-Salvan/x-aeon_agents/commit/8d5696aabf0356f2c172f60b23ec715c8201f001)
* [refactor: simplify PR creation and agent run tracking](https://github.com/Muriel-Salvan/x-aeon_agents/commit/53f5eb0d3581393f5ec120c62fe4095da1df3a72)
* [Fix agent parameter access in CLI connection and agent runner](https://github.com/Muriel-Salvan/x-aeon_agents/commit/2dc5fb8a17e307bd7a02734a6a0b26071730725b)
* [refactor: improve agent feedback and artifact handling](https://github.com/Muriel-Salvan/x-aeon_agents/commit/87154ccdc751e6e5e2b8239881f715da9dfd3d18)
* [fix: join code diffs with double newlines for proper formatting](https://github.com/Muriel-Salvan/x-aeon_agents/commit/ebe9f91bc9b243b3c077bfe08f9d76b5e59b81a7)
* [feat(agents): mark implementation plan artifact as requiring review](https://github.com/Muriel-Salvan/x-aeon_agents/commit/4995b3d2b294d6f09e2d11788dd2b7575bee477a)
* [fix: push branch before checking for existing PR](https://github.com/Muriel-Salvan/x-aeon_agents/commit/12d3d5bd66d2444d96b104fa995e879ea13d4705)
* [refactor: standardize agent input/output artifact definitions](https://github.com/Muriel-Salvan/x-aeon_agents/commit/e2c9b4036dd6d14323c0ddce110caee19a09117f)
* [feat: add GitHub token support and PR creation for requirements implementation](https://github.com/Muriel-Salvan/x-aeon_agents/commit/de5e5a7e4f2b241a5730721eaeaa0d390b3b22da)
* [refactor: standardize artifact references in agent instructions](https://github.com/Muriel-Salvan/x-aeon_agents/commit/15c587b45d0e58316856974c35ff06099163de0d)
* [refactor: rename artifacts to use ARTIFACT_ prefix for clarity](https://github.com/Muriel-Salvan/x-aeon_agents/commit/3f955279beec1ddadf2a2b990b8589bd84803825)
* [Refactor documentation agent instructions for clarity and structure](https://github.com/Muriel-Salvan/x-aeon_agents/commit/1c8c6ada9e40a266f1058d7129060f157d73f6ea)
* [fix: Handle new_task event in CLI connection](https://github.com/Muriel-Salvan/x-aeon_agents/commit/aa51ee8f8dfb011ecf144523d8647a6bc13e14cc)
* [refactor: improve message formatting for better readability](https://github.com/Muriel-Salvan/x-aeon_agents/commit/3a37e904ed9beda995d335833b36ad4444fcb3f3)
* [refactor: simplify git commit process by removing temporary file usage](https://github.com/Muriel-Salvan/x-aeon_agents/commit/e8089465b537a1a38586e1e9946894adfb0733c7)
* [refactor: improve git diff handling and agent workflow](https://github.com/Muriel-Salvan/x-aeon_agents/commit/1705f973e54a9eeb8cde5ee67d47cd2ed47cc232)
* [refactor: add Git dependency and improve diff handling in agents](https://github.com/Muriel-Salvan/x-aeon_agents/commit/90220a654cf71762b72645053c3da685468cd5cb)
* [refactor: update checklist execution instructions for consistency](https://github.com/Muriel-Salvan/x-aeon_agents/commit/8b1d796ad02fa0df62faeb41540b86df00b31b6e)
* [feat: add code diff interpretation system with automated testing and git integration](https://github.com/Muriel-Salvan/x-aeon_agents/commit/8a54527f8051b173e079d6db74b2bd0ba7517a40)
* [refactor: simplify agent configuration and improve plan execution workflow](https://github.com/Muriel-Salvan/x-aeon_agents/commit/b21e1739cd233a5d910a2c26617a25be25503952)
* [refactor: standardize temporary directory paths to .x-aeon_agents/tmp](https://github.com/Muriel-Salvan/x-aeon_agents/commit/b947335ebb219b14bac6ac55cd09b961dda0155d)
* [feat: Add step-based execution with persistence and run ID support](https://github.com/Muriel-Salvan/x-aeon_agents/commit/5e90fb60429338c540ee198ef1406a2ac5ef5bb2)
* [refactor: remove unused `gen_helpers` dependency and simplify agent instructions](https://github.com/Muriel-Salvan/x-aeon_agents/commit/09739a9b4e159d1a8f30fd72833bcc797d83d451)
* [refactor: simplify agent instructions and add objectives](https://github.com/Muriel-Salvan/x-aeon_agents/commit/b698502a5bcf848f31facb8e835052cc4e6b1d10)
* [refactor: enhance agent configuration with structured input/output artifacts](https://github.com/Muriel-Salvan/x-aeon_agents/commit/6d46bb13da67eb3f1ad0428555cde9982f651946)
* [chore: add git status output to agent workflow debugging](https://github.com/Muriel-Salvan/x-aeon_agents/commit/e82bab73661cb50c1d9f270607a805994b5bea0d)
* [fix: Improve tester and documenter agents with better regression handling and documentation workflow](https://github.com/Muriel-Salvan/x-aeon_agents/commit/abd0dde68bf2408702d5fe0cee969af3a1cb50ea)
* [refactor: simplify agent configuration and improve plan execution flow](https://github.com/Muriel-Salvan/x-aeon_agents/commit/a8d09e53fe355f8793fbec149966cab860cc93ed)
* [fix: Correct partial message filtering logic in Cline and CLI connections](https://github.com/Muriel-Salvan/x-aeon_agents/commit/0508807b140ba00fea2c3555d9e6b59a596a0386)
* [feat(cline): add support for new message types and API error handling](https://github.com/Muriel-Salvan/x-aeon_agents/commit/d0da089cfd973aa4a0cc45c5e908ee9467d9723e)
* [refactor: enhance Cline prompt method with ignore_partials option](https://github.com/Muriel-Salvan/x-aeon_agents/commit/af4c4a974e038f971f3e63df1fb8dcda7c84a419)
* [refactor: move GitHub issue implementation to generic requirements function](https://github.com/Muriel-Salvan/x-aeon_agents/commit/0a9db50a65ba38e5a12b1d624ddd7ceb1d821864)
* [Add support for new tool types in Cline logging](https://github.com/Muriel-Salvan/x-aeon_agents/commit/faf791bf37739c0b85f13e34b0bf797ef234cdcb)
* [feat: Add support for task progress and completion messages in Cline](https://github.com/Muriel-Salvan/x-aeon_agents/commit/5d0cce4e48ac4a273a4589b8c3364eab83721cfb)
* [refactor: improve message formatting and add ellipsized text support](https://github.com/Muriel-Salvan/x-aeon_agents/commit/3d2bbe328fa02e06995674a3361e98e5fdc434ea)
* [refactor: extract prompt execution logic and improve logging](https://github.com/Muriel-Salvan/x-aeon_agents/commit/a9045afec3e28fcf0d0e6245f1cb6dad2665acd3)
* [Refactor agent implementation workflow with temporary directory and enhanced skill management](https://github.com/Muriel-Salvan/x-aeon_agents/commit/434c60afb8100d44846cf402a992ce18ecde001a)
* [Add skills system and update project structure](https://github.com/Muriel-Salvan/x-aeon_agents/commit/5910a7180c6fde02080ed204bf4ce696397ed3e1)
* [Update branch references from 'main' to 'github/main' in validation skill](https://github.com/Muriel-Salvan/x-aeon_agents/commit/0df2163f31491acd2d0004602de1e62135a3bcd1)
* [refactor: migrate from custom CLI to Ruby script and integrate ai-agents](https://github.com/Muriel-Salvan/x-aeon_agents/commit/3134b08a29db129131d6768a5c698446ccac573e)
* [Update TODO.md](https://github.com/Muriel-Salvan/x-aeon_agents/commit/5c89b80c124df8d370c909638f32214ee727ade1)

## Changes for {model-name}
### Patches

* [feat: Add automated Pull Request comment handling system with GitHub API integration](https://github.com/Muriel-Salvan/x-aeon_agents/commit/629ddba789ef402797cd51715ae249a5e757c5cb)

## Changes for {model}
### Patches

* [feat: Add automated Pull Request comment handling system with GitHub API integration](https://github.com/Muriel-Salvan/x-aeon_agents/commit/629ddba789ef402797cd51715ae249a5e757c5cb)

# [v1.0.17](https://github.com/Muriel-Salvan/x-aeon_agents/compare/v1.0.16...v1.0.17) (2026-02-24 15:04:01)

### Patches

* [feat: add plan mode support to some skill templates](https://github.com/Muriel-Salvan/x-aeon_agents/commit/12edb263d4e168a7863465008658433e2528e5b1)
* [refactor: extract ERB block transformation and improve skill documentation](https://github.com/Muriel-Salvan/x-aeon_agents/commit/38e012c6b1e5342f6ae529f7668f59fb11495525)
* [refactor: rename skill-related methods for consistency](https://github.com/Muriel-Salvan/x-aeon_agents/commit/ecc2e6b20b7cac39c7dac89e7fdc2ac363ae7934)
* [Refactor skill metadata generation and update skill definitions](https://github.com/Muriel-Salvan/x-aeon_agents/commit/62ae05ca8e2f49485c33d7bd38c414413b07c764)

# [v1.0.16](https://github.com/Muriel-Salvan/x-aeon_agents/compare/v1.0.15...v1.0.16) (2026-02-23 20:31:23)

### Patches

* [fix(skillkit): correct subpath in installed skills metadata](https://github.com/Muriel-Salvan/x-aeon_agents/commit/10a5ea0a7f4bf9657cc70ca0d4b5acd972576e59)

# [v1.0.15](https://github.com/Muriel-Salvan/x-aeon_agents/compare/v1.0.14...v1.0.15) (2026-02-23 16:04:49)

### Patches

* [refactor(generate_skills): migrate CLI from optparse to Thor](https://github.com/Muriel-Salvan/x-aeon_agents/commit/b3441edc3cebf49138a671ffd4dee9cfa9d08c03)

# [v1.0.14](https://github.com/Muriel-Salvan/x-aeon_agents/compare/v1.0.13...v1.0.14) (2026-02-23 14:33:17)

### Patches

* [feat: add bin executables to gemspec and update dependency format docs](https://github.com/Muriel-Salvan/x-aeon_agents/commit/eab8c6057cf32d376e36504d3b028ec5e3f9b652)

# [v1.0.13](https://github.com/Muriel-Salvan/x-aeon_agents/compare/v1.0.12...v1.0.13) (2026-02-23 13:47:42)

### Patches

* [chore: make bin scripts executable](https://github.com/Muriel-Salvan/x-aeon_agents/commit/5854f48de87069efa497088c11639606ec906203)
* [feat(generate_skills): add support for custom destination directory](https://github.com/Muriel-Salvan/x-aeon_agents/commit/040fe99e0720306511886977b96b0e1b115ee6ac)

# [v1.0.12](https://github.com/Muriel-Salvan/x-aeon_agents/compare/v1.0.11...v1.0.12) (2026-02-23 13:14:56)

### Patches

* [refactor: convert skill dependencies from comma-separated strings to arrays](https://github.com/Muriel-Salvan/x-aeon_agents/commit/36f9f90f03bb11a09b0608e35d5bd67a2ed57074)
* [fix: handle nil return from skill_config to prevent NoMethodError](https://github.com/Muriel-Salvan/x-aeon_agents/commit/56224b3a07e590a9506159734ee6cc26c2bd0d58)
* [feat: add improving-cline-reflection skill for Cline rules](https://github.com/Muriel-Salvan/x-aeon_agents/commit/a4f855965dc6a8dc2a463a272d844e9e261f07e5)
* [feat: add applying-test-conventions skill with test writing best practices](https://github.com/Muriel-Salvan/x-aeon_agents/commit/47f2dace8ad5f18ef38a0fc36e585336041b8e3f)
* [feat: add addressing-pull-request-comments skill and update README guidance](https://github.com/Muriel-Salvan/x-aeon_agents/commit/375f91383ea1101c9147dd5b20b9ace6acfdb5ab)
* [refactor: normalize skill conventions to sentence case and add rule helper](https://github.com/Muriel-Salvan/x-aeon_agents/commit/2d21a57f94fc8e4813407933021cb1e2fc12fe6f)
* [feat: add per-skill .skill_config.yml support in skill generation](https://github.com/Muriel-Salvan/x-aeon_agents/commit/df588da54f0b5197bee24e60e9d1f89fb7c1bb35)
* [refactor(gen_helpers): centralize skill metadata with frontmatter and skill_goal](https://github.com/Muriel-Salvan/x-aeon_agents/commit/0988c459360f8b354d7c38a844a3d0f5e07235fa)
* [docs: document new skill syntax conventions and add analyze-github-issue skill](https://github.com/Muriel-Salvan/x-aeon_agents/commit/df8f22e606b211a081a5a1d0df5d49620c8daec3)
* [feat: add tmp_path helper and update skills to use configurable temp folder](https://github.com/Muriel-Salvan/x-aeon_agents/commit/9d27d2355cbe9f5c528edb5ad3e4c5dc1d993ad8)
* [refactor: convert class methods to instance methods for ERB evaluation](https://github.com/Muriel-Salvan/x-aeon_agents/commit/8c018d2323f76a7e07a9ef9a83ff7b04ba4741d1)

# [v1.0.11](https://github.com/Muriel-Salvan/x-aeon_agents/compare/v1.0.10...v1.0.11) (2026-02-17 16:41:56)

### Patches

* [feat(ci): add Node and skillkit to CI pipeline, improve skill descriptions](https://github.com/Muriel-Salvan/x-aeon_agents/commit/ce22db56283378b0ba7941229803639484bdf59c)

# [v1.0.10](https://github.com/Muriel-Salvan/x-aeon_agents/compare/v1.0.9...v1.0.10) (2026-02-17 16:37:02)

### Patches

* [feat: add skillkit manifest and installation script](https://github.com/Muriel-Salvan/x-aeon_agents/commit/347d4df36b58589ab30a7ec78a5662888e6b1dc7)
* [feat: rename Skills.spec to Skillfile and add initial skill configuration](https://github.com/Muriel-Salvan/x-aeon_agents/commit/543a632931a85a42c8a948964dbbc33e4c4fe664)
* [feat: add skills installation CLI with Skills.spec DSL support](https://github.com/Muriel-Salvan/x-aeon_agents/commit/1c56e8698e52e77d7a903b7d1502ea30b732d935)

# [v1.0.9](https://github.com/Muriel-Salvan/x-aeon_agents/compare/v1.0.8...v1.0.9) (2026-02-16 17:21:40)

### Patches

* [feat(skills): add skill dependencies metadata and renumber implementation steps](https://github.com/Muriel-Salvan/x-aeon_agents/commit/f43eddf13c8ac3b11e416ecab462a8a97a418fec)

# [v1.0.8](https://github.com/Muriel-Salvan/x-aeon_agents/compare/v1.0.7...v1.0.8) (2026-02-16 17:19:33)

### Patches

* [feat(skills): add dependency metadata to skill definitions](https://github.com/Muriel-Salvan/x-aeon_agents/commit/f3c1a440444ff77997645b3f2ae434339026d02d)

# [v1.0.7](https://github.com/Muriel-Salvan/x-aeon_agents/compare/v1.0.6...v1.0.7) (2026-02-13 17:34:02)

### Patches

* [refactor: reorganize GitHub issue implementation workflow](https://github.com/Muriel-Salvan/x-aeon_agents/commit/060f17c95cdf58710b4d37eae106c5a4e1686a2b)

# [v1.0.6](https://github.com/Muriel-Salvan/x-aeon_agents/compare/v1.0.5...v1.0.6) (2026-02-13 17:00:24)

### Patches

* [test: add gen_helpers_spec.rb with specs for skill checklist generation](https://github.com/Muriel-Salvan/x-aeon_agents/commit/52227c1a582d48e9dafc5f4e25810dc1607cbbca)
* [feat: add define_ordered_todo_list helper for auto-numbering skill sections](https://github.com/Muriel-Salvan/x-aeon_agents/commit/bf05d62fbfa5a6d7a80f61523174c8430d42182e)
* [refactor: separate skills source and generated output directories](https://github.com/Muriel-Salvan/x-aeon_agents/commit/2ee3e9ee6ff8df235eae107b3d6ccbbe05b935e9)

# [v1.0.5](https://github.com/Muriel-Salvan/x-aeon_agents/compare/v1.0.4...v1.0.5) (2026-02-12 19:35:11)

### Patches

* [feat(gen_helpers): add skill-specific naming to execution checklists](https://github.com/Muriel-Salvan/x-aeon_agents/commit/6c3c71b5a1740c37f277e2c938bf9d181d77f743)

# [v1.0.4](https://github.com/Muriel-Salvan/x-aeon_agents/compare/v1.0.3...v1.0.4) (2026-02-12 19:10:01)

### Patches

* [feat: add ERB templating system for skills generation](https://github.com/Muriel-Salvan/x-aeon_agents/commit/47da216f23623d28c37fddae5d6d3eae712c9c55)

# [v1.0.3](https://github.com/Muriel-Salvan/x-aeon_agents/compare/v1.0.2...v1.0.3) (2026-02-12 14:48:48)

### Patches

* [docs: clarify skill instructions for issues, paths, TOC and validation steps](https://github.com/Muriel-Salvan/x-aeon_agents/commit/4431f6080e2cb01388f1dc2095da33632e1264f4)

# [v1.0.2](https://github.com/Muriel-Salvan/x-aeon_agents/compare/v1.0.1...v1.0.2) (2026-02-12 13:54:28)

### Patches

* [docs(creating-pull-request): clarify gh CLI wrapper requirement](https://github.com/Muriel-Salvan/x-aeon_agents/commit/9c48dbd1a43d54b814aaa2c74057b723d240e868)
* [docs: standardize GitHub capitalization across skill documentation](https://github.com/Muriel-Salvan/x-aeon_agents/commit/15c1acc6e874d2ad394eb98374284c4d3f3ce79b)

# [v1.0.1](https://github.com/Muriel-Salvan/x-aeon_agents/compare/v1.0.0...v1.0.1) (2026-02-12 12:58:21)

### Patches

* [docs: add skill writing guidelines and command prefix standards](https://github.com/Muriel-Salvan/x-aeon_agents/commit/14b22fc5fcff923615ac98b85693727334e7bf38)
* [feat(skills): add creating-pull-request skill and refine commit workflow](https://github.com/Muriel-Salvan/x-aeon_agents/commit/cd3fc5257b0ca3ee32e45aef77859023f248182f)

# [v0.0.1](https://github.com/Muriel-Salvan/x-aeon_agents/compare/...v0.0.1) (2026-02-11 16:56:34)

### Patches

* [ci(github-actions): disable credential persistence in checkout](https://github.com/Muriel-Salvan/x-aeon_agents/commit/33aede9a1f3f5b4cd5302f8f27b439fdfd45fe95)
* [ci: use dedicated token for semantic-release](https://github.com/Muriel-Salvan/x-aeon_agents/commit/6a6df54269f988c336c09ca3c1f148b2675975e1)
* [ci(workflow): add missing GITHUB_TOKEN for semantic-release](https://github.com/Muriel-Salvan/x-aeon_agents/commit/29d077ab5b814d02efdbf17eef6ca52307936165)
* [test: add RSpec test suite and fix database connection leak](https://github.com/Muriel-Salvan/x-aeon_agents/commit/a903a959e81531b24802335f597045e7993cfc41)
* [ci: add GitHub Actions workflow for automated testing and releases](https://github.com/Muriel-Salvan/x-aeon_agents/commit/f54395fa9902fd6e88e645b50163b2ef7c0482f6)
* [feat: add implementing-github-issue skill](https://github.com/Muriel-Salvan/x-aeon_agents/commit/6f51b7f38425eafec0cd5005fc95f5bf9d1995dc)
* [fix(wsl-portable): handle special chars via delayed expansion](https://github.com/Muriel-Salvan/x-aeon_agents/commit/161a01ac3229043a1885fb7052b0d0d92eb7c788)
* [fix(skill): require quotes around CLI args in wsl-portable](https://github.com/Muriel-Salvan/x-aeon_agents/commit/268ee80b72f4f5546f4bce6641166b87f94bccbe)
* [fix(wsl-portable-bash): strip surrounding quotes from arguments](https://github.com/Muriel-Salvan/x-aeon_agents/commit/d2853a0140f051bb08f81aac2aa79a32f87573ad)
* [docs: add warning against quoting original_cli in WSL portable skill](https://github.com/Muriel-Salvan/x-aeon_agents/commit/8ed0a2d57f4f21b22b57d12e58e7af0c1b3f151f)
