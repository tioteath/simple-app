require 'spec_helper'

describe port 80 do
  it { is_expected.to be_listening.with :tcp }
end

describe command 'curl --verbose  --location http://localhost' do
  its(:stderr) { is_expected.to match 'HTTP/1.1 200 OK' }
end
