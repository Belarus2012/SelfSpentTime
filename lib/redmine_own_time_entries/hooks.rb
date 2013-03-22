module RedmineOwnTimeEntries
  class Hooks < Redmine::Hook::ViewListener

    render_on :view_issues_show_details_bottom, :partial => 'own_time_entries_issue_patch'

  end
end
