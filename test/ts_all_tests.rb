# Require the unit tests
require File.dirname(__FILE__) + '/unit/ts_all_unittests.rb'

# Require the functional tests
require File.dirname(__FILE__) + '/functional/ts_all_functionaltests.rb'

# Require the integration tests
#['account_test.rb',
#'admin_test.rb',
#'issues_test.rb',
#'projects_test.rb'
#].each do |file|
#  File.dirname(__FILE__) + '/integration/' + file
#end

#http://guides.rubyonrails.org/testing.html
#It is a good idea to run the following commands before testing:
# rake db:test:purge
# rake db:test:prepare