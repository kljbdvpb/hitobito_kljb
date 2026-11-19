# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

module Kljb
  module BoardMembership
    # Server-seitige Sperre: In Vorstand/Leiterrunde wird keine neue Person angelegt, auch nicht
    # per manipuliertem POST. Nach dem Verknuepfen einer bestehenden Person ohne Mitgliedsrolle
    # in der Ortsgruppe erscheint ein Hinweis (keine Sperre, siehe EXEMPT_ROLE_TYPES).
    module RolesController
      def create
        super
        flash_membership_missing
      end

      private

      def create_entry_and_person
        if entry.person.new_record? && Kljb::BoardMembership.no_new_person?(entry.group)
          entry.errors.add(:base, I18n.t('kljb.board_membership.new_person_blocked'))
          return false
        end

        super
      end

      # Core-create hat respond_with bereits aufgerufen; der Flash wird erst am Requestende
      # geschrieben und gilt fuer den Redirect (Core setzt flash[:alert] ebenso, siehe
      # last_primary_group_role_deleted).
      def flash_membership_missing
        role = entry
        return unless role.persisted? && Kljb::BoardMembership.membership_missing?(role)

        flash[:alert] = I18n.t('kljb.board_membership.membership_missing',
                               person: role.person.to_s, layer: role.group.layer_group.to_s)
      end
    end
  end
end
