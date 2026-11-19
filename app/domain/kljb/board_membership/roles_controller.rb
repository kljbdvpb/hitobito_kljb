# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

module Kljb
  module BoardMembership
    # Server-seitige Sperre: In Vorstand, Leiterrunde und RV-Vorstand (ausser Geist) wird keine
    # neue Person angelegt, auch nicht
    # per manipuliertem POST. Nach dem Verknuepfen einer bestehenden Person ohne Mitgliedsrolle
    # in der Ortsgruppe erscheint ein Hinweis (keine Sperre, siehe EXEMPT_ROLE_TYPES).
    module RolesController
      def create
        super
        flash_membership_missing
      end

      private

      # Rollentyp-Wechsel (Core: update -> change_type) legt eine neue Rolle an: gleicher Hinweis.
      def change_type_successfull
        super
        flash_membership_missing
      end

      def create_entry_and_person
        if entry.person.new_record? &&
           Kljb::BoardMembership.new_person_blocked?(entry.group, entry.type)
          entry.errors.add(:base, blocked_message(entry.group))
          return false
        end

        super
      end

      def blocked_message(group)
        Kljb::BoardMembership.new_person_blocked_message(group)
      end

      # Core-create hat respond_with bereits aufgerufen; der Flash wird erst am Requestende
      # geschrieben und gilt fuer den Redirect (Core setzt flash[:alert] ebenso, siehe
      # last_primary_group_role_deleted).
      def flash_membership_missing
        role = entry
        return unless role.persisted? && Kljb::BoardMembership.membership_missing?(role)

        flash[:alert] = I18n.t('kljb.board_membership.membership_missing',
                               person: role.person.to_s,
                               layer: Kljb::BoardMembership.membership_scope_label(role.group))
      end
    end
  end
end
