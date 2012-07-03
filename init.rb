require 'redmine'
require 'admin_menu_hooks'

Redmine::Plugin.register :redmine_import_reqpro do
  name 'RequisistePro Importer'
  author 'Thomas Kohler'
  description 'Redmine plugin for importing RequisitePro Baselines.'
  version '0.5'

  project_module :reqproimporter do
    permission :reqproimporter, :reqproimporter => :index
  end
  menu :admin_menu, :reqproimporter, { :controller => 'reqproimporter', :action => 'index' }, :caption => :label_reqproimport, :after => :projects, :html => { :class => 'icon icon-import-reqpro' }
end
