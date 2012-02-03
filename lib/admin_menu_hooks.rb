class AdminMenuHooks < Redmine::Hook::ViewListener
  def view_layouts_base_html_head(context = { })
    stylesheet_link_tag 'reqproimporter.css', :plugin => 'redmine_import_reqpro', :media => 'screen'
  end
end