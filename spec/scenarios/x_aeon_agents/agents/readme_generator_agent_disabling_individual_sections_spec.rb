describe XAeonAgents::Agents::ReadmeGeneratorAgent do
  describe 'disabling individual sections' do
    before do
      stub_doctoc
      stub_readme_generator_run
    end

    XAeonAgentsTest::Helpers::GenerateReadme.readme_sections.each_key do |section_name|
      context "when disabling the #{section_name} section" do
        let(:default_run_kwargs) do
          { gen_about: true }.merge(
            readme_sections.keys.to_h { |name| [:"gen_#{name}", name != section_name] }
          )
        end

        it "does not include the #{section_name} section when disabled from a new README" do
          run_readme_generator(run_kwargs: default_run_kwargs, existing_content: nil)
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
            run_kwargs: default_run_kwargs,
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
