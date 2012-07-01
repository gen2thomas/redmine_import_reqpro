#Problemloesungsversuche fuer:
#No route matches {:controller=>"reqproimporter", :action=>"index"
#
ActionController::Routing::Routes.draw do |map|
  #allgemeine Formulierung:
  #map.connect ':controller/:action/:id'
  #gezielte Formulierungen:
  map.connect "/reqproimporter", :controller => "reqproimporter", :action => "index" , :conditions => { :method => :get }
  map.connect "/reqproimporter/listprojects", :controller => "reqproimporter", :action => "listprojects" , :conditions => { :method => :post }
  map.connect "/reqproimporter/matchusers", :controller => "reqproimporter", :action => "matchusers" , :conditions => { :method => :post }
  map.connect "/reqproimporter/matchtrackers", :controller => "reqproimporter", :action => "matchtrackers" , :conditions => { :method => :post }
  map.connect "/reqproimporter/matchversions", :controller => "reqproimporter", :action => "matchversions" , :conditions => { :method => :post }
  map.connect "/reqproimporter/matchattributes", :controller => "reqproimporter", :action => "matchattributes" , :conditions => { :method => :post }
  map.connect "/reqproimporter/do_import_and_result", :controller => "reqproimporter", :action => "do_import_and_result" , :conditions => { :method => :post }
  
end
