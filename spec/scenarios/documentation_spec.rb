require 'English'
require 'tmpdir'

RSpec.describe 'Documentation generation' do
  it 'successfully generates the yard documentation' do
    Dir.mktmpdir do |temp_dir|
      `bundle exec yard doc --fail-on-warning --db #{temp_dir}/.yardoc --output-dir #{temp_dir}/doc`
      expect($CHILD_STATUS.exitstatus).to eq(0)
      # Verify the docs were created
      index_file = "#{temp_dir}/doc/index.html"
      expect(File).to exist(index_file)
      expect(File.size(index_file)).to be > 0
    end
  end

  it 'reports 100% of documented code' do
    stdout = `bundle exec yard stats --list-undoc --fail-on-warning`
    expect($CHILD_STATUS.exitstatus).to eq(0)
    expect(stdout).to include('100.00% documented')
  end
end
