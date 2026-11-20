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
      Group::RegionalverbandVorstand
    ].freeze

    # Nur diese Rolle direkt in der Ortsgruppe gilt als "ist erfasst" (Fachentscheidung
    # 2026-11-19: Foerdermitglied zaehlt nicht).
    MEMBER_ROLE_TYPES = %w[
      Group::Ortsgruppe::Mitglied
    ].freeze

    # Geistliche Begleitung: darf auch ohne Mitgliedsrolle vergeben werden (kein Hinweis/Bericht)
    # und ist von der Sperre "keine neue Person" ausgenommen (Neuanlage erlaubt).
    EXEMPT_ROLE_TYPES = %w[
      Group::OrtsgruppeVorstand::Geist
      Group::RegionalverbandVorstand::Geist
    ].freeze

    class << self
      def no_new_person?(group)
        group = group.object if group.try(:decorated?) # Draper: echten Gruppentyp pruefen
        group.present? && NO_NEW_PERSON_GROUP_TYPES.include?(group.class.sti_name)
      end

      # Ist das Anlegen einer NEUEN Person fuer diese Gruppe und diesen Rollentyp gesperrt?
      # Rollentyp = sti_name (String) oder Rollenklasse; ausgenommene Rollen (Geist) duerfen.
      def new_person_blocked?(group, role_type)
        no_new_person?(group) && !exempt_role_type?(role_type)
      end

      # Bezugsort der Mitgliedschaft fuer Texte: OG-Layer bzw. "einer Ortsgruppe in <RV>".
      def membership_scope_label(group)
        layer = group.layer_group
        return layer.to_s unless layer.is_a?(::Group::Regionalverband)

        I18n.t('kljb.board_membership.membership_in_region', region: layer.to_s)
      end

      # Rollenbezeichnung der ausgenommenen Rolle (Geist) in dieser Gruppe, z.B. fuer Texte/Link;
      # nil, wenn die Gruppe keine solche Rolle hat (Leiterrunde).
      def exempt_role_type(group)
        group = group.object if group.try(:decorated?)
        names = group.class.role_types.map(&:sti_name)
        EXEMPT_ROLE_TYPES.find { |type| names.include?(type) }
      end

      def new_person_blocked_message(group)
        label = exempt_role_label(group)
        return I18n.t('kljb.board_membership.new_person_blocked') unless label

        I18n.t('kljb.board_membership.new_person_blocked_exempt', role: label)
      end

      def exempt_role_label(group)
        type = exempt_role_type(group)
        type && type.constantize.model_name.human
      end

      def exempt_role_type?(role_type)
        name = role_type.respond_to?(:sti_name) ? role_type.sti_name : role_type.to_s
        EXEMPT_ROLE_TYPES.include?(name)
      end

      # Personen mit aktiver Rolle in +group+ (Vorstand/Leiterrunde), die in der Ortsgruppe
      # (Layer) keine Mitgliedsrolle haben. Ausgenommene Rollen (Geist) zaehlen nicht.
      def without_membership(group)
        return ::Person.none unless no_new_person?(group)
        # Verwaiste Gruppe (Layer fehlt): defensiv keine Treffer statt NoMethodError
        layer = group.layer_group
        return ::Person.none if layer.nil?

        ::Person.where(id: ::Role.active_and_future.where(group_id: group.id)
                             .where.not(type: EXEMPT_ROLE_TYPES)
                             .select(:person_id))
              .where.not(id: member_person_ids(layer))
      end

      # Hinweis noetig fuer genau diese Rolle (Vorstand/Leiterrunde, nicht ausgenommen,
      # Person ohne Mitgliedsrolle in der Ortsgruppe)?
      def membership_missing?(role)
        return false unless no_new_person?(role.group)
        return false if EXEMPT_ROLE_TYPES.include?(role.type)
        layer = role.group.layer_group
        return false if layer.nil? # verwaiste Gruppe: kein Hinweis

        !member_person_ids(layer).where(person_id: role.person_id).exists?
      end

      private

      # Ortsgruppe: Mitgliedsrolle in der eigenen Ortsgruppe. Regionalverband: Mitgliedsrolle in
      # irgendeiner Ortsgruppe unterhalb dieses Regionalverbands (nicht in fremden RV).
      # Auch Rollen mit start_on in der Zukunft zaehlen (::Role.active_and_future).
      def member_person_ids(layer_group)
        ::Role.active_and_future.without_archived
              .where(group_id: member_group_ids(layer_group), type: MEMBER_ROLE_TYPES)
              .select(:person_id)
      end

      def member_group_ids(layer_group)
        if layer_group.is_a?(::Group::Regionalverband)
          # frisch laden: lft/rgt der im Speicher gehaltenen Instanz koennen veraltet sein
          ::Group.find(layer_group.id).descendants.without_archived
                 .where(type: ::Group::Ortsgruppe.sti_name).select(:id)
        else
          [layer_group.id]
        end
      end
    end
  end
end
