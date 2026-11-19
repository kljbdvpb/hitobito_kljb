# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

# Altersgruppen der jaehrlichen Mitgliederzaehlung (Stichtag 01.09.), ergaenzend zu
# members_normal/members_discounted. Alle Spalten nullable: leer bis zum naechsten Stichtagslauf
# bzw. bis zum Backfill (rake hitobito_kljb:member_counts:backfill_age_groups).
class AddAgeGroupCountsToGroups < ActiveRecord::Migration[6.1]
  def change
    add_column :groups, :members_under_14, :integer
    add_column :groups, :members_from_14, :integer
    add_column :groups, :members_up_to_27, :integer
    add_column :groups, :members_without_birthday, :integer
  end
end
