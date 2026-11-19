# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

module Kljb
  module BoardMembership
    # Rollenformular: in Vorstand/Leiterrunde nur "Bestehende Person suchen", ohne Umschalter
    # auf "Neue Person erfassen" (Core: RolesHelper#swappable_role_add_fieldset, 2 Aufrufe aus
    # roles/_person_fields). Der Neu-Block wird weggelassen, der Such-Block ohne Link gerendert.
    module RolesHelper
      def swappable_role_add_fieldset(*keys, &block)
        return super unless Kljb::BoardMembership.no_new_person?(entry.group)
        return unless keys.first == :create_new # Neu-Block entfaellt

        title = safe_join([t('roles.person_fields.search_existing_person'),
                           content_tag(:small, t('kljb.board_membership.form_hint'))], ' ')
        field_set_tag(title, class: 'person-fields') { block.call }
      end
    end
  end
end
