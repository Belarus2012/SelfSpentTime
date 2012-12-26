module OwnTimeEntries
  module TimeEntryReportsControllerPatch

    def self.included(base)
      base.class_eval do

        # override method to add conditions to filter
        def report
          @criterias = params[:criterias] || []
          @criterias = @criterias.select{|criteria| @available_criterias.has_key? criteria}
          @criterias.uniq!
          @criterias = @criterias[0,3]

          @columns = (params[:columns] && %w(year month week day).include?(params[:columns])) ? params[:columns] : 'month'

          retrieve_date_range

          unless @criterias.empty?
            sql_select = @criterias.collect{|criteria| @available_criterias[criteria][:sql] + " AS " + criteria}.join(', ')
            sql_group_by = @criterias.collect{|criteria| @available_criterias[criteria][:sql]}.join(', ')
            sql_condition = ''

            if @project.nil?
              sql_condition = Project.allowed_to_condition(User.current, :view_time_entries)
            elsif @issue.nil?
              sql_condition = @project.project_condition(Setting.display_subprojects_issues?)
            else
              sql_condition = "#{Issue.table_name}.root_id = #{@issue.root_id} AND #{Issue.table_name}.lft >= #{@issue.lft} AND #{Issue.table_name}.rgt <= #{@issue.rgt}"
            end

            # =========== patch start ===========
            if @project
              roles = User.current.roles_for_project(@project)
              view_time_entries = roles.detect { |role| role.allowed_to?(:view_time_entries) }
              view_only_own_time_entries = roles.detect { |role| role.allowed_to?(:view_only_own_time_entries) }
              # if user should not see time_entries (settings - view_time_entries)
              # but user has permission to see own time_entries (settings - view_only_own_time_entries)
              # add a condition time_entries.user_id = User.current.id
              if !view_time_entries && view_only_own_time_entries
                sql_condition << " AND #{TimeEntry.table_name}.user_id = #{User.current.id}"
              end
            end
            # =========== patch end ===========

            sql = "SELECT #{sql_select}, tyear, tmonth, tweek, spent_on, SUM(hours) AS hours"
            sql << " FROM #{TimeEntry.table_name}"
            sql << time_report_joins
            sql << " WHERE"
            sql << " (%s) AND" % sql_condition
            sql << " (spent_on BETWEEN '%s' AND '%s')" % [ActiveRecord::Base.connection.quoted_date(@from), ActiveRecord::Base.connection.quoted_date(@to)]
            sql << " GROUP BY #{sql_group_by}, tyear, tmonth, tweek, spent_on"

            @hours = ActiveRecord::Base.connection.select_all(sql)

            @hours.each do |row|
              case @columns
              when 'year'
                row['year'] = row['tyear']
              when 'month'
                row['month'] = "#{row['tyear']}-#{row['tmonth']}"
              when 'week'
                row['week'] = "#{row['tyear']}-#{row['tweek']}"
              when 'day'
                row['day'] = "#{row['spent_on']}"
              end
            end

            @total_hours = @hours.inject(0) {|s,k| s = s + k['hours'].to_f}

            @periods = []
            # Date#at_beginning_of_ not supported in Rails 1.2.x
            date_from = @from.to_time
            # 100 columns max
            while date_from <= @to.to_time && @periods.length < 100
              case @columns
              when 'year'
                @periods << "#{date_from.year}"
                date_from = (date_from + 1.year).at_beginning_of_year
              when 'month'
                @periods << "#{date_from.year}-#{date_from.month}"
                date_from = (date_from + 1.month).at_beginning_of_month
              when 'week'
                @periods << "#{date_from.year}-#{date_from.to_date.cweek}"
                date_from = (date_from + 7.day).at_beginning_of_week
              when 'day'
                @periods << "#{date_from.to_date}"
                date_from = date_from + 1.day
              end
            end
          end

          respond_to do |format|
            format.html { render :layout => !request.xhr? }
            format.csv  { send_data(report_to_csv(@criterias, @periods, @hours), :type => 'text/csv; header=present', :filename => 'timelog.csv') }
          end
        end

        private

          def find_optional_project
            if !params[:issue_id].blank?
              @issue = Issue.find(params[:issue_id])
              @project = @issue.project
            elsif !params[:project_id].blank?
              @project = Project.find(params[:project_id])
            end

            # =========== patch start ===========
            # allow user open #index if view_time_entries or view_only_own_time_entries is allowed
            unless User.current.allowed_to?(:view_time_entries, @project, :global => true) ||
                   User.current.allowed_to?(:view_only_own_time_entries, @project, :global => true)
              deny_access
            end
            # =========== patch end ===========
          end

      end
    end
  end
end
