# frozen_string_literal: true

# This migration comes from decidim (originally 20181025082245)

class AddTimestampsToComponents < ActiveRecord::Migration[5.2]
  def change
    add_timestamps :decidim_components, null: true
    Decidim::Component.update_all(created_at: Time.current, updated_at: Time.current)

    change_column_null :decidim_components, :created_at, false
    change_column_null :decidim_components, :updated_at, false
  end
end
