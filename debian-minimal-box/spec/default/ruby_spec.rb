require 'spec_helper'

describe command('/usr/bin/ruby -v') do
  it "should installd ruby" do
    should return_stdout 'ruby 1.9.3p194 (2012-04-20 revision 35410) [i486-linux]'
  end
end
