require 'redmine'

Redmine::Plugin.register :redmine_own_time_entries do
  name 'Redmine Own Time Entries plugin'
  author '//Twinslash'
  description 'Plugin to show users only own time entries in a project'
  version '0.0.1'
  url ''
  author_url 'http://twinslash.com'

  # Now it is tested only for this version
  requires_redmine '1.3'

  project_module :time_tracking do
    permission :view_only_own_time_entries, { :view_only_own_time_entries => nil }
  end

end
