# frozen_string_literal: true

# This migration comes from decidim_debates (originally 20201126112752)
# This file has been modified by `decidim upgrade:migrations` task on 2026-02-17 08:03:06 UTC
class ArchiveDebates < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_debates_debates, :archived_at, :datetime
    add_index :decidim_debates_debates, :archived_at
  end
end
