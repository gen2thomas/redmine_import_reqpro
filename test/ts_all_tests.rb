# Require the unit tests
['tc_files_helper.rb',
'tc_projects_helper.rb',
'tc_requirements_issues_helper.rb'
].each do |file|
  require File.dirname(__FILE__) + '/unit/' + file
end

# Require the functional tests
#['application_controller_test.rb',
#'feeds_controller_test.rb',
#'my_controller_test.rb',
#'projects_controller_test.rb',
#'search_controller_test.rb',
#'timelog_controller_test.rb'
#].each do |file|
#  File.dirname(__FILE__) + '/functional/' + file
#end

# Require the integration tests
#['account_test.rb',
#'admin_test.rb',
#'issues_test.rb',
#'projects_test.rb'
#].each do |file|
#  File.dirname(__FILE__) + '/integration/' + file
#end
