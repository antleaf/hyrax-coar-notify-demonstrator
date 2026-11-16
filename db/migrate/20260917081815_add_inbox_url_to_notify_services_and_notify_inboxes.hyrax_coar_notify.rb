# This migration comes from hyrax_coar_notify (originally 20260616093423)
class AddInboxUrlToNotifyServicesAndNotifyInboxes < ActiveRecord::Migration[7.2]
  def change
    add_column :notify_services, :inbox_url, :string
    add_column :notify_inboxes, :inbox_url, :string
  end
end
