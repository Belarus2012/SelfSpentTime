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
          @news = @project.news.limit(5).includes(:author, :project).reorder("#{News.table_name}.created_on DESC").all
          @trackers = @project.rolled_up_trackers

          cond = @project.project_condition(Setting.display_subprojects_issues?)

          @open_issues_by_tracker = Issue.visible.open.where(cond).count(:group => :tracker)
          @total_issues_by_tracker = Issue.visible.where(cond).count(:group => :tracker)

          # =========== patch start ===========
          if User.current.allowed_to?(:view_time_entries, @project) || User.current.allowed_to?(:view_only_own_time_entries, @project)
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
