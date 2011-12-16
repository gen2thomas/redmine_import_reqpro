require 'redmine'

Redmine::Plugin.register :import_reqpro do
  name 'RequisistePro Importer'
  author 'Thomas Kohler'
  description 'Redmine plugin for importing RequisistePro Baselines.'
  version '0.1'

  project_module :rpbimporter do
    permission :rpbimport, :rpbimporter => :index
  end
  menu :project_menu, :rpbimporter, { :controller => 'rpbimporter', :action => 'index' }, :caption => :label_rpbimport, :before => :settings, :param => :project_id
end
