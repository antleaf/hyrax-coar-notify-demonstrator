# hyrax-coar-notify also ships a task with this name. This app owns it (docker-entrypoint.sh
# depends on it), so drop the gem's copy first; otherwise Rake runs both and every action twice.
Rake::Task['db:exists'].clear if Rake::Task.task_defined?('db:exists')

namespace :db do
  desc "Checks to see if the database exists"
  task :exists do
    begin
      Rake::Task['environment'].invoke
      ActiveRecord::Base.connection
    rescue
      exit 1
    else
      exit 0
    end
  end
end
