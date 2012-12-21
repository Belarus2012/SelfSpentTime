module OwnTimeEntries
  module ApplicationControllerPatch

    def self.included(base)
      base.class_eval do

        # override method to change authorization logic
        # Authorize the user for the requested action
        def authorize(ctrl = params[:controller], action = params[:action], global = false)
          allowed = User.current.allowed_to?({:controller => ctrl, :action => action}, @project || @projects, :global => global)
          # =========== patch start ===========
          # if it is not allowed but ctrl/action = timelog/index
          # and view_only_own_time_entries is enabled for user then allow user to timelog page
          if !allowed && (ctrl == "timelog" && action == "index")
            allowed = User.current.allowed_to?(:view_only_own_time_entries, @project || @projects, :global => true)
          end
          # =========== patch end ===========
          if allowed
            true
          else
            if @project && @project.archived?
              render_403 :message => :notice_not_authorized_archived_project
            else
              deny_access
            end
          end
        end

      end
    end
  end
end
