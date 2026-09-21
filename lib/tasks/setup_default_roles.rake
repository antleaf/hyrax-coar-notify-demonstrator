# hyrax-coar-notify also ships a task with this name. This app owns it (docker-entrypoint.sh
# depends on it), so drop the gem's copy first; otherwise Rake runs both and every action twice.
Rake::Task['notify:setup_default_roles'].clear if Rake::Task.task_defined?('notify:setup_default_roles')

namespace :notify do
  desc 'Setup Hyrax, will read from specified file usage: notify:setup_default_roles'
  task :"setup_default_roles", [:seedfile] => :environment do |task, args|
    admin = Role.where(name: "admin").first_or_create!
    review_service_manager = Role.where(name: "review_service_manager").first_or_create!
  end
end