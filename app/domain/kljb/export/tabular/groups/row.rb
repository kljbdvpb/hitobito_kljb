# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

# Zeile des Gruppenexports: abgeleitete Gesamtzahl der Mitglieder (normal + verguenstigt).
module Kljb::Export::Tabular::Groups::Row
  # nil (leere Zelle), solange die Gruppe keine Zaehlung hat (z. B. Nicht-Ortsgruppen)
  def members_total
    return if entry.members_normal.nil? && entry.members_discounted.nil?

    entry.members_normal.to_i + entry.members_discounted.to_i
  end
end
