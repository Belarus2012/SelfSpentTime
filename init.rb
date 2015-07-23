require 'redmine'
require 'redmine_own_time_entries'

Redmine::Plugin.register :redmine_own_time_entries do
  name 'Redmine Own Time Entries plugin'
  author '//Twinslash'
  description 'Plugin to show users only own time entries in a project'
  version '0.0.5'
  url 'https://github.com/Belarus2012/SelfSpentTime'
  author_url 'http://twinslash.com'

  project_module :time_tracking do
    permission :view_only_own_time_entries, { :view_only_own_time_entries => nil }
  end

end
