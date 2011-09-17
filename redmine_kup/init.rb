require 'redmine'
# Patches to the Redmine core.  Will eventually not work in development mode
require_dependency 'issue_patch'
require_dependency 'issue_relation_patch'

Redmine::Plugin.register :redmine_kup do
  name 'Redmine KUP plugin'
  author 'Thomas Kohler'
  description 'A Plugin to add some <Kohler Unified Process> specific traces like <Rational Unified Process>'
  version '0.0.1'
end
