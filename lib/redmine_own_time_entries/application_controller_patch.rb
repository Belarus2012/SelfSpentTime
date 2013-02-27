module OwnTimeEntries
  module ApplicationControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable

        alias_method_chain :authorize, :own_time_entries
      end
    end

    module InstanceMethods

      def authorize_with_own_time_entries(ctrl = params[:controller], action = params[:action], global = false)
        # if ctrl/action = timelog/index
        # and view_only_own_time_entries is enabled for user then allow user to open timelog page
        if (ctrl == "timelog" &&
            ["index", "report"].include?(action) &&
            User.current.allowed_to?(:view_only_own_time_entries, @project || @projects, :global => true))

          true
        else
          authorize_without_own_time_entries(ctrl, action, global)
        end
      end

    end
  end
end
