# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

module Kljb
  module BoardMembership
    # CSV-Import in Vorstand/Leiterrunde: Zeilen, die eine NEUE Person ergaeben wuerden, werden
    # als fehlerhaft gemeldet (Vorschau und Import). Treffer der Core-Dublettenerkennung
    # (bestehende Person) werden wie bisher nur um die Rolle ergaenzt.
    module PersonImporter
      private

      def valid?(import_person)
        return false unless super

        if import_person.new_record? && Kljb::BoardMembership.no_new_person?(group)
          import_person.person.errors.add(:base, I18n.t('kljb.board_membership.new_person_blocked'))
          return false
        end

        true
      end
    end
  end
end
