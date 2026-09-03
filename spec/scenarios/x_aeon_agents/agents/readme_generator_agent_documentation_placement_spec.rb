describe XAeonAgents::Agents::ReadmeGeneratorAgent do
  describe 'documentation placement' do
    let(:default_run_kwargs) { {} }

    before do
      stub_doctoc
      stub_readme_generator_run
    end

    it 'places Documentation just after Public API when Documentation does not exist before' do
      run_readme_generator(
        run_kwargs: default_run_kwargs,
        existing_content: <<~README
          # Old Project

          Old description

          ## Quick start

          Old quick start

          ## Public API

          Old public API

          ## How it works

          Old how it works
        README
      )
      doc_index = header_index('Documentation')
      expect(doc_index).to be > header_index('Public API')
      expect(doc_index).to be < header_index('How it works')
    end

    it 'places Documentation after Requirements if neither Public API nor Features exist before' do
      run_readme_generator(
        run_kwargs: default_run_kwargs.merge(gen_features: false, gen_public_api: false),
        existing_content: <<~README
          # Old Project

          Old description

          ## Requirements

          Old requirements

          ## Quick start

          Old quick start
        README
      )
      doc_index = header_index('Documentation')
      expect(doc_index).to be > header_index('Requirements')
      expect(doc_index).to be < header_index('Quick start')
    end

    it 'keeps Documentation before Features when it was already there' do
      run_readme_generator(
        run_kwargs: default_run_kwargs,
        existing_content: <<~README
          # Old Project

          Old description

          ## Documentation

          Old documentation

          ## Features

          Old features
        README
      )
      expect(header_index('Documentation')).to be < header_index('Features')
    end
  end
end
