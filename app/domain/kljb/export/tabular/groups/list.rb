# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

# Gruppenexport des Wagons: Mitgliederzahlen bleiben als Spalten erhalten
# (normale und vergünstigte Mitglieder, Spalten aus AddMemberCountsToGroups).
module Kljb::Export::Tabular::Groups::List
  MEMBER_COUNT_ATTRS = %i[members_normal members_discounted].freeze

  def attributes
    (super + MEMBER_COUNT_ATTRS).uniq
  end
end
