module OwnTimeEntriesProjectPatch

  def self.included(base)
    base.extend ClassMethods
    base.class_eval do
      unloadable

      class << self
        alias_method_chain :allowed_to_condition, :own_time_entries
      end

    end
  end


  module ClassMethods
    # Returns a SQL conditions string used to find all projects for which +user+ has the given +permission+
    #
    # Valid options:
    # * :project => limit the condition to project
    # * :with_subprojects => limit the condition to project and its subprojects
    # * :member => limit the condition to the user projects
    def allowed_to_condition_with_own_time_entries(user, permission, options={}, &block)
      statement = allowed_to_condition_without_own_time_entries(user, permission, options, &block)
      project_list = []
      if user.logged? and !user.admin? and (permission == :view_time_entries)
        user.projects_by_role.each do |role, projects|
          if role.allowed_to?(:view_only_own_time_entries) && projects.any?
            project_list << projects.collect(&:id)
          end
        end
      end

      if project_list.empty?
        statement
      else
        statement.chomp("))") << " OR (#{Project.table_name}.id IN (#{project_list.flatten.uniq.join(',')}) AND (#{TimeEntry.table_name}.user_id = #{user.id}))))"
      end
    end

  end

end
