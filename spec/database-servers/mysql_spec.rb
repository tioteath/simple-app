require 'spec_helper'

describe port 3306 do
  it { is_expected.to be_listening.with :tcp }
end

describe command 'mysql employees -e "show tables"' do
  its(:stdout) { is_expected.to match 'Tables_in_employees' }
end
