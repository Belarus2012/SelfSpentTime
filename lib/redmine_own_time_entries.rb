require_dependency 'redmine_own_time_entries/hooks'

require 'redmine_own_time_entries/own_time_entries_project_patch'
require 'redmine_own_time_entries/own_time_entries_issue_patch'
require 'redmine_own_time_entries/projects_controller_patch'
require 'redmine_own_time_entries/application_controller_patch'

Rails.configuration.to_prepare do
  Project.send(:include, OwnTimeEntriesProjectPatch)
  Issue.send(:include, OwnTimeEntriesIssuePatch)

  ProjectsController.send(:include, OwnTimeEntries::ProjectsControllerPatch)
  ApplicationController.send(:include, OwnTimeEntries::ApplicationControllerPatch)
end
