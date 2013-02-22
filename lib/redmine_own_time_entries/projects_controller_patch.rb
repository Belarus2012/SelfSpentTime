module OwnTimeEntries
  module ProjectsControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        before_filter :own_time_entries_total_hours, :only => :show
      end
    end

    module InstanceMethods

      # calculate @total_hours if allowed_to? :view_only_own_time_entries
      def own_time_entries_total_hours
        if User.current.allowed_to?(:view_only_own_time_entries, @project) && !User.current.allowed_to?(:view_time_entries, @project)
          cond = @project.project_condition(Setting.display_subprojects_issues?)
          @total_hours = TimeEntry.visible.sum(:hours, :include => :project, :conditions => cond).to_f
        end
      end

    end

  end
end
