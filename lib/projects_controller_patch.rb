module OwnTimeEntries
  module ProjectsControllerPatch

    def self.included(base)
      base.class_eval do

        # override method to add conditions to filter
        # Show @project
        def show
          if params[:jump]
            # try to redirect to the requested menu item
            redirect_to_project_menu_item(@project, params[:jump]) && return
          end

          @users_by_role = @project.users_by_role
          @subprojects = @project.children.visible.all
          @news = @project.news.find(:all, :limit => 5, :include => [ :author, :project ], :order => "#{News.table_name}.created_on DESC")
          @trackers = @project.rolled_up_trackers

          cond = @project.project_condition(Setting.display_subprojects_issues?)

          @open_issues_by_tracker = Issue.visible.count(:group => :tracker,
                                                  :include => [:project, :status, :tracker],
                                                  :conditions => ["(#{cond}) AND #{IssueStatus.table_name}.is_closed=?", false])
          @total_issues_by_tracker = Issue.visible.count(:group => :tracker,
                                                  :include => [:project, :status, :tracker],
                                                  :conditions => cond)

          # =========== patch start ===========
          if User.current.allowed_to?(:view_time_entries, @project) || User.current.allowed_to?(:view_only_own_time_entries, @project)
            roles = User.current.roles_for_project(@project)
            view_time_entries = roles.detect { |role| role.allowed_to?(:view_time_entries) }
            view_only_own_time_entries = roles.detect { |role| role.allowed_to?(:view_only_own_time_entries) }
            # if user should not see time_entries (settings - view_time_entries)
            # but user has permission to see own time_entries (settings - view_only_own_time_entries)
            # add a condition time_entries.user_id = User.current.id
            if !view_time_entries && view_only_own_time_entries
              cond << " AND #{TimeEntry.table_name}.user_id = #{User.current.id} "
            end
            # =========== patch end ===========
            @total_hours = TimeEntry.visible.sum(:hours, :include => :project, :conditions => cond).to_f
          end

          @key = User.current.rss_key

          respond_to do |format|
            format.html
            format.api
          end
        end
      end
    end
  end
end
