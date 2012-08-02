# Require the unit tests
['tc_files_helper.rb',
  'tc_projects_helper.rb',
  'tc_ext_projects_helper.rb',
  'tc_requirements_issues_helper.rb',
  'tc_users_helper.rb'
].each do |file|
  require File.dirname(__FILE__) + '/' + file
end
