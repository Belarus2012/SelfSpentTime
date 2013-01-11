module OwnTimeEntriesIssuePatch
  def self.included(base)
    base.class_eval do
      unloadable

      # Patch: add options to arguments and use additional condition if option[:user]
      #
      # Returns the total number of hours spent on this issue and its descendants
      #
      # Example:
      #   spent_hours => 0.0
      #   spent_hours => 50.2
      def total_spent_hours(options = {})
        conditions = options[:user] ? "#{TimeEntry.table_name}.user_id = #{options[:user].id}" : "1=1"
        @total_spent_hours ||= self_and_descendants.sum("#{TimeEntry.table_name}.hours",
          :joins => "LEFT JOIN #{TimeEntry.table_name} ON #{TimeEntry.table_name}.issue_id = #{Issue.table_name}.id",
          :conditions => conditions).to_f || 0.0
      end

    end
  end

end
