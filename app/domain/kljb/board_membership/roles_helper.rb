# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

module Kljb
  module BoardMembership
    # Rollenformular: in Vorstand/Leiterrunde/RV-Vorstand nur "Bestehende Person suchen", ohne
    # Umschalter auf "Neue Person erfassen" (Core: RolesHelper#swappable_role_add_fieldset,
    # 2 Aufrufe aus roles/_person_fields). Der Neu-Block wird weggelassen, der Such-Block ohne
    # Link gerendert.
    #
    # Ausnahme Geistliche Begleitung: Der Rollentyp ist im Formular ein Select, das ohne JS-Umbau
    # nicht auf die Personenfelder wirkt. Daher entscheidet nur der beim Oeffnen des Formulars
    # (bzw. nach Fehler beim erneuten Rendern) gewaehlte Rollentyp: ist er Geist, bietet das
    # Formular beide Varianten wie in normalen Gruppen. Sonst steht im Hinweis ein Link auf das
    # Formular mit vorgewaehltem Rollentyp Geist. Massgeblich bleibt die Server-Sperre.
    module RolesHelper
      def swappable_role_add_fieldset(*keys, &block)
        return super unless Kljb::BoardMembership.new_person_blocked?(entry.group, entry.type)
        return unless keys.first == :create_new # Neu-Block entfaellt

        title = safe_join([t('roles.person_fields.search_existing_person'),
                           content_tag(:small, board_membership_form_hint)], ' ')
        field_set_tag(title, class: 'person-fields') { block.call }
      end

      private

      def board_membership_form_hint
        hint = t('kljb.board_membership.form_hint')
        geist = Kljb::BoardMembership.exempt_role_type(entry.group)
        return hint unless geist

        label = Kljb::BoardMembership.exempt_role_label(entry.group)
        safe_join([hint,
                   link_to(t('kljb.board_membership.form_geist_link', role: label),
                           new_group_role_path(entry.group, role: { type: geist }))], ' ')
      end
    end
  end
end
