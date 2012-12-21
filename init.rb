require 'redmine'

# require 'own_time_entries_project_patch'
# Rails.configuration.to_prepare do
#   Project.send(:include, OwnTimeEntriesProjectPatch)
# end

require 'dispatcher'
# require 'timelog_controller_patch'
require 'projects_controller_patch'
Dispatcher.to_prepare do
#   TimelogController.send(:include, OwnTimeEntries::TimelogControllerPatch)
  ProjectsController.send(:include, OwnTimeEntries::ProjectsControllerPatch)
end

Redmine::Plugin.register :redmine_own_time_entries do
  name 'Redmine Own Time Entries plugin'
  author '//Twinslash'
  description 'Plugin to show users only own time entries in a project'
  version '0.0.1'
  url ''
  author_url 'http://twinslash.com'

  # Now it is tested only for this version
  requires_redmine '1.4'

  project_module :time_tracking do
    permission :view_only_own_time_entries, { :view_only_own_time_entries => nil }
  end

end
