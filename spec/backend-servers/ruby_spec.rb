require 'spec_helper'

describe command 'ruby --version' do
  its(:stdout) { is_expected.to match "ruby 2." }
end

describe command 'bundle --version' do
  its(:stdout) { is_expected.to match "Bundler version 1." }
end
