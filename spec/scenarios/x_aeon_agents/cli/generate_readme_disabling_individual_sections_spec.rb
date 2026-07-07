describe XAeonAgents::Cli, '#generate_readme' do
  context 'when disabling individual sections' do
    before do
      stub_doctoc
      stub_readme_generator_run
    end

    XAeonAgentsTest::Helpers::GenerateReadme.readme_sections.each_key do |section_name|
      context "when disabling the #{section_name} section" do
        let(:default_cli_args) do
          %w[--about] + readme_sections.keys.map { |name| name == section_name ? "--no-#{name}" : "--#{name}" }
        end

        it "does not include the #{section_name} section when disabled from a new README" do
          run_readme_generator(existing_content: nil)
          readme_sections.each do |name, title|
            if name == section_name
              expect_no_section(title)
            else
              expect_section(title, "Generated content for #{name}")
            end
          end
        end

        it "does not modify the #{section_name} section when disabled" do
          run_readme_generator(
            existing_content: <<~EO_README
              # Test project

              ## Table of contents

              - [Old](#old)

              #{readme_sections.map { |name, title| "## #{title}\n\nOld content for #{name}" }.join("\n\n")}
            EO_README
          )
          expect(readme_content).to include('Test Project')
          expect(readme_content).to include('A test project')
          readme_sections.each do |name, title|
            if name == section_name
              expect_section(title, "Old content for #{name}")
            else
              expect_section(title, "Generated content for #{name}")
            end
          end
        end
      end
    end
  end
end
