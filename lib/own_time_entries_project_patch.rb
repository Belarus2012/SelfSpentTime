module OwnTimeEntriesProjectPatch

  def self.included(base)
    base.class_eval do
      unloadable

      # Returns a SQL conditions string used to find all projects for which +user+ has the given +permission+
      #
      # Valid options:
      # * :project => limit the condition to project
      # * :with_subprojects => limit the condition to project and its subprojects
      # * :member => limit the condition to the user projects
      def self.allowed_to_condition(user, permission, options={})
        perm = Redmine::AccessControl.permission(permission)
        base_statement = (perm && perm.read? ? "#{Project.table_name}.status <> #{Project::STATUS_ARCHIVED}" : "#{Project.table_name}.status = #{Project::STATUS_ACTIVE}")
        if perm && perm.project_module
          # If the permission belongs to a project module, make sure the module is enabled
          base_statement << " AND #{Project.table_name}.id IN (SELECT em.project_id FROM #{EnabledModule.table_name} em WHERE em.name='#{perm.project_module}')"
        end
        if options[:project]
          project_statement = "#{Project.table_name}.id = #{options[:project].id}"
          project_statement << " OR (#{Project.table_name}.lft > #{options[:project].lft} AND #{Project.table_name}.rgt < #{options[:project].rgt})" if options[:with_subprojects]
          base_statement = "(#{project_statement}) AND (#{base_statement})"
        end

        if user.admin?
          base_statement
        else
          statement_by_role = {}
          unless options[:member]
            role = user.logged? ? Role.non_member : Role.anonymous
            if role.allowed_to?(permission)
              statement_by_role[role] = "#{Project.table_name}.is_public = #{connection.quoted_true}"
            end
          end
          if user.logged?
            user.projects_by_role.each do |role, projects|
              # =========== patch start ===========
              if role.allowed_to?(permission) && projects.any?
                statement_by_role[role] = "#{Project.table_name}.id IN (#{projects.collect(&:id).join(',')})"
              elsif permission == :view_time_entries && role.allowed_to?(:view_only_own_time_entries) && projects.any?
                statement_by_role[role] = "#{Project.table_name}.id IN (#{projects.collect(&:id).join(',')}) AND #{TimeEntry.table_name}.user_id = #{user.id}"
              end
              # =========== patch end ===========
            end
          end
          if statement_by_role.empty?
            "1=0"
          else
            if block_given?
              statement_by_role.each do |role, statement|
                if s = yield(role, user)
                  statement_by_role[role] = "(#{statement} AND (#{s}))"
                end
              end
            end
            "((#{base_statement}) AND (#{statement_by_role.values.join(' OR ')}))"
          end
        end
      end

    end
  end

end
