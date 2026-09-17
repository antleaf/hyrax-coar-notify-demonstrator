# frozen_string_literal: true

# coar_notify_inbox's migrations are declared against ActiveRecord::Migration[8.0], but this
# app runs Rails 7.2. Its engine is loaded (hyrax-coar-notify depends on it) even though we
# don't mount its routes here (the inbox is treated as an external service), which means its
# db/migrate directory is still merged into this app's migration paths. Without this, any
# db:migrate run raises "Unknown migration version '8.0'".
if defined?(ActiveRecord::Migration::Compatibility)
  module ActiveRecord::Migration::Compatibility
    class << self
      prepend(Module.new do
        def find(version)
          version = "7.2" if version.to_s == "8.0"
          super(version)
        end
      end)
    end
  end
end
