module OwnTimeEntries
  module TimelogControllerPatch

    def self.included(base)
      base.class_eval do

        # override method to add conditions to filter
        def index
          sort_init 'spent_on', 'desc'
          sort_update 'spent_on' => 'spent_on',
                      'user' => 'user_id',
                      'activity' => 'activity_id',
                      'project' => "#{Project.table_name}.name",
                      'issue' => 'issue_id',
                      'hours' => 'hours'

          cond = ARCondition.new
          if @issue
            cond << "#{Issue.table_name}.root_id = #{@issue.root_id} AND #{Issue.table_name}.lft >= #{@issue.lft} AND #{Issue.table_name}.rgt <= #{@issue.rgt}"
          elsif @project
            cond << @project.project_condition(Setting.display_subprojects_issues?)
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
              cond << "#{TimeEntry.table_name}.user_id = #{User.current.id}"
            end
          end
          # =========== patch end ===========

          retrieve_date_range
          cond << ['spent_on BETWEEN ? AND ?', @from, @to]

          respond_to do |format|
            format.html {
              # Paginate results
              @entry_count = TimeEntry.visible.count(:include => [:project, :issue], :conditions => cond.conditions)
              @entry_pages = TimelogController::Paginator.new self, @entry_count, per_page_option, params['page']
              @entries = TimeEntry.visible.find(:all,
                                        :include => [:project, :activity, :user, {:issue => :tracker}],
                                        :conditions => cond.conditions,
                                        :order => sort_clause,
                                        :limit  =>  @entry_pages.items_per_page,
                                        :offset =>  @entry_pages.current.offset)
              @total_hours = TimeEntry.visible.sum(:hours, :include => [:project, :issue], :conditions => cond.conditions).to_f

              render :layout => !request.xhr?
            }
            format.api  {
              @entry_count = TimeEntry.visible.count(:include => [:project, :issue], :conditions => cond.conditions)
              @offset, @limit = api_offset_and_limit
              @entries = TimeEntry.visible.find(:all,
                                        :include => [:project, :activity, :user, {:issue => :tracker}],
                                        :conditions => cond.conditions,
                                        :order => sort_clause,
                                        :limit  => @limit,
                                        :offset => @offset)
            }
            format.atom {
              entries = TimeEntry.visible.find(:all,
                                       :include => [:project, :activity, :user, {:issue => :tracker}],
                                       :conditions => cond.conditions,
                                       :order => "#{TimeEntry.table_name}.created_on DESC",
                                       :limit => Setting.feeds_limit.to_i)
              render_feed(entries, :title => l(:label_spent_time))
            }
            format.csv {
              # Export all entries
              @entries = TimeEntry.visible.find(:all,
                                        :include => [:project, :activity, :user, {:issue => [:tracker, :assigned_to, :priority]}],
                                        :conditions => cond.conditions,
                                        :order => sort_clause)
              send_data(entries_to_csv(@entries), :type => 'text/csv; header=present', :filename => 'timelog.csv')
            }
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
