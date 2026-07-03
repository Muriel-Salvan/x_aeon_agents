require 'English'

RSpec.describe 'Code Quality' do
  it 'runs RuboCop without any errors or offenses' do
    stdout = `rubocop 2>&1`

    expect($CHILD_STATUS.exitstatus).to eq(0), "Rubocop checks failed:\n#{stdout}"
    expect(stdout).to include('no offenses detected')
  end
end
