# frozen_string_literal: true

# This migration comes from decidim_conferences (originally 20210408204953)
# This file has been modified by `decidim upgrade:migrations` task on 2026-02-17 08:03:06 UTC
class AllowNullLogoColumnInDecidimConferencesPartnersTable < ActiveRecord::Migration[6.0]
  def change
    change_column_null :decidim_conferences_partners, :logo, true
  end
end
