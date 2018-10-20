require 'spec_helper'

describe service 'app' do
  it { is_expected.to be_enabled }
  it { is_expected.to be_running }
end

describe port 3000 do
  it { is_expected.to be_listening.with :tcp }
end
