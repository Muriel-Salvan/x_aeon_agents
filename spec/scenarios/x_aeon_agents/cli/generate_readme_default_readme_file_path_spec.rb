describe XAeonAgents::Cli, '#generate_readme' do
  it 'uses README.md in the current directory when --readme-file-path is not specified' do
    stub_doctoc
    stub_readme_generator_run
    default_readme = File.expand_path('README.md')
    # Mock reading the existing README.md so we do not touch the real file.
    # Other File.read calls (e.g. the temporary TOC file read by the mocked doctoc)
    # still behave normally.
    allow(File).to receive(:read).and_wrap_original do |original_read, path, *args, **kwargs|
      if path == default_readme
        <<~EO_README
          # Old Project

          Old description

          #{readme_sections.map { |_name, title| "## #{title}\n\nOld content" }.join("\n\n")}
        EO_README
      else
        original_read.call(path, *args, **kwargs)
      end
    end
    allow(File).to receive(:exist?).and_wrap_original do |original_exist, path, *args, **kwargs|
      path == default_readme || original_exist.call(path, *args, **kwargs)
    end
    # Capture the content passed to File.write without modifying the real README.md.
    # Other File.write calls (e.g. the temporary TOC file) are still performed so the
    # mocked doctoc command can read from them.
    new_readme_content = nil
    allow(File).to receive(:write).and_wrap_original do |original_write, path, content, *args, **kwargs|
      if path == default_readme
        new_readme_content = content
      else
        original_write.call(path, content, *args, **kwargs)
      end
    end
    run_cli('generate-readme')
    expect(new_readme_content).to eq <<~EO_README
      #{readme_header}

      ## Table of contents

      - [Quick start](#quick-start)
      - [Requirements](#requirements)
      - [Features](#features)
      - [Public API](#public-api)
      - [Documentation](#documentation)
      - [How it works](#how-it-works)
      - [Development](#development)
      - [Contributing](#contributing)
      - [License](#license)

      ## Quick start

      Generated content for quick_start

      ## Requirements

      Generated content for requirements

      ## Features

      Generated content for features

      ## Public API

      Generated content for public_api

      ## Documentation

      Generated content for documentation

      ## How it works

      Generated content for how_it_works

      ## Development

      Generated content for development

      ## Contributing

      Generated content for contributing

      ## License

      Generated content for license
    EO_README
  end
end
