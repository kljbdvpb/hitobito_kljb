# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

# Dubletten-Vorbeugung (T75): Vorstand und Leiterrunde einer Ortsgruppe sollen nur bestehende
# Personen verknuepfen, nicht neue anlegen. Wer dort neu angelegt wird, ohne vorher als
# Mitglied der Ortsgruppe erfasst zu sein, ist sonst eine Dublette (siehe docs/dubletten-vorstand.md).
#
# Die Listen unten sind die einzige Stelle fuer die fachliche Festlegung; Aenderungen hier wirken
# auf Formular, Server-Sperre, CSV-Import, Hinweis und Bericht gleichermassen.
module Kljb
  module BoardMembership
    # Gruppentypen, in denen KEINE neue Person angelegt werden darf (nur Zuordnung bestehender).
    NO_NEW_PERSON_GROUP_TYPES = %w[
      Group::OrtsgruppeVorstand
      Group::OrtsgruppeLeiterrunde
    ].freeze

    # Rollen direkt in der Ortsgruppe, die als "ist erfasst" gelten (Mitglied, Foerdermitglied).
    MEMBER_ROLE_TYPES = %w[
      Group::Ortsgruppe::Mitglied
      Group::Ortsgruppe::Foerdermitglied
    ].freeze

    # Vorstandsrollen, die legitim auch ohne Mitgliedsrolle vergeben werden (kein Hinweis/Bericht).
    EXEMPT_ROLE_TYPES = %w[
      Group::OrtsgruppeVorstand::Geist
    ].freeze

    class << self
      def no_new_person?(group)
        group = group.object if group.try(:decorated?) # Draper: echten Gruppentyp pruefen
        group.present? && NO_NEW_PERSON_GROUP_TYPES.include?(group.class.sti_name)
      end

      # Personen mit aktiver Rolle in +group+ (Vorstand/Leiterrunde), die in der Ortsgruppe
      # (Layer) keine Mitgliedsrolle haben. Ausgenommene Rollen (Geist) zaehlen nicht.
      def without_membership(group)
        return Person.none unless no_new_person?(group)

        Person.where(id: Role.where(group_id: group.id).where.not(type: EXEMPT_ROLE_TYPES)
                             .select(:person_id))
              .where.not(id: member_person_ids(group.layer_group_id))
      end

      # Hinweis noetig fuer genau diese Rolle (Vorstand/Leiterrunde, nicht ausgenommen,
      # Person ohne Mitgliedsrolle in der Ortsgruppe)?
      def membership_missing?(role)
        return false unless no_new_person?(role.group)
        return false if EXEMPT_ROLE_TYPES.include?(role.type)

        !Role.where(group_id: role.group.layer_group_id, type: MEMBER_ROLE_TYPES, person_id: role.person_id).exists?
      end

      private

      def member_person_ids(layer_group_id)
        Role.where(group_id: layer_group_id, type: MEMBER_ROLE_TYPES).select(:person_id)
      end
    end
  end
end
