module OwnTimeEntriesRolePatch

  def self.included(base)
    base.send(:include, InstanceMethods)

    base.class_eval do
      alias_method_chain :allowed_to?, :own_time_entries
    end
  end

  module InstanceMethods

    def allowed_to_with_own_time_entries?(action)
      result = allowed_to_without_own_time_entries?(action)
      # return true if action is not allowed but permission :view_only_own_time_entries is enabled
      result || (action == :view_time_entries && allowed_permissions.include?(:view_only_own_time_entries))
    end

  end

end
