# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

module Groups
  class MemberPaymentStatus
    # Stichtag fuer das Alter (Mitgliedsbeitrag): 01.09. (Fachentscheidung, vorher 31.08.)
    AGE_CUTOFF_DATE = [9, 1].freeze

    MEMBER_ROLE_TYPES = ["Group::Ortsgruppe::Mitglied"].freeze

    # Altersgrenzen der Mitgliederzaehlung (Alter in vollen Jahren am Stichtag, siehe Person#years)
    AGE_LIMIT_YOUNG = 14 # unter 14 | ab 14
    AGE_LIMIT_YOUTH = 27 # bis einschliesslich 27

    # Nur diese Spalten schreibt der Backfill; members_normal/members_discounted nie.
    AGE_ATTRIBUTES = %i[members_under_14 members_from_14 members_up_to_27
      members_without_birthday].freeze

    class << self
      def cutoff_date
        now = Date.current
        year = if now >= Date.new(now.year, *AGE_CUTOFF_DATE)
          now.year
        else
          now.year - 1
        end

        Date.new(year, *AGE_CUTOFF_DATE)
      end
    end

    def initialize(group)
      @group = group
    end

    def update
      return false unless @group.layer?

      result = @group.update(
        members_normal: normal_members,
        members_discounted: discounted_members,
        **age_attributes
      )
      unless result
        Rails.logger.warn("MemberPaymentStatus: Gruppe #{@group.id} nicht gespeichert: " \
                          "#{@group.errors.full_messages.to_sentence}")
      end
      result
    end

    # Altersgruppen der aktuellen Mitglieder des Layers, Alter am Stichtag (cutoff_date).
    # Je Person genau einmal gezaehlt; members_up_to_27 ueberschneidet sich mit under_14/from_14,
    # under_14 + from_14 + without_birthday = Anzahl Mitglieder.
    def age_attributes(on: self.class.cutoff_date, people: all_members_of_layer)
      counts = AGE_ATTRIBUTES.index_with(0)
      people.distinct.pluck(:id, :birthday).each do |_id, birthday|
        if birthday.nil?
          counts[:members_without_birthday] += 1
          next
        end

        years = Person.new(birthday: birthday).years(on)
        counts[years < AGE_LIMIT_YOUNG ? :members_under_14 : :members_from_14] += 1
        counts[:members_up_to_27] += 1 if years <= AGE_LIMIT_YOUTH
      end
      counts
    end

    # Backfill: schreibt NUR die Altersspalten (update_columns: keine Validierung, kein
    # updated_at), members_normal/members_discounted bleiben unberuehrt. Mitglieder werden aus
    # start_on/end_on der Rollen zum Stichtag rekonstruiert (siehe members_at).
    def backfill_age_attributes!(at: self.class.cutoff_date)
      return false unless @group.layer?

      attrs = age_attributes(on: at, people: members_at(at))
      @group.update_columns(attrs)
      attrs
    end

    # Personen mit einer Mitglied-Rolle im Layer, die am Stichtag aktiv war. Gleiche Regel wie
    # der Default-Scope der Rollen beim Joblauf (Core 2.11.5): start_on <= Stichtag (oder leer)
    # und end_on >= Stichtag (oder leer). Rollen, die beendet wurden, bleiben mit end_on erhalten;
    # hart geloeschte Rollen (< minimum_days_to_archive Tage alt) sind nicht rekonstruierbar.
    # archived_at wird wie im Live-Pfad nicht gefiltert.
    def members_at(date)
      roles = Role.active(date.to_date)
        .where(type: MEMBER_ROLE_TYPES, group_id: layer_group_ids)
      Person.where(id: roles.select(:person_id))
    end

    def normal_members
      # distinct: eine Person mit zwei aktiven Mitglied-Rollen im Layer zaehlt einmal
      # (Person.joins(:roles) liefert sonst eine Zeile je Rolle).
      @normal_members ||= all_members_of_layer.distinct.count - discounted_members
    end

    def discounted_members
      @discounted_members ||= underage_members_with_two_siblings.count
    end

    private

    # Auch inzwischen geloeschte Gruppen des Layers (fuer die Historie)
    def layer_group_ids
      Group.with_deleted.where(layer_group_id: @group.layer_group_id).select(:id)
    end

    def all_members_of_layer
      Person.joins(:roles)
        .where(roles: {
          group: @group.groups_in_same_layer,
          type: MEMBER_ROLE_TYPES
        })
    end

    # Geschwisterrabatt (Nutzerentscheidung 2026-11-19): fuer "drittes und weiteres Kind" zaehlen
    # nur Geschwister (gleicher family_key), die selbst ein aktives Mitglied desselben Layers
    # sind. Geschwister in anderen Ortsgruppen oder ohne Mitgliedsrolle werden nicht gezaehlt.
    # Reihenfolge nach Geburtstag, dann die ab dem dritten Kind am Stichtag Minderjaehrigen.
    def underage_members_with_two_siblings
      layer_members = Person.where(id: all_members_of_layer.select(:id))
        .where.not(family_key: nil).order(:family_key, :birthday, :id)

      layer_members.group_by(&:family_key).flat_map { |_key, family|
        family.drop(2).select { |person| person.underage?(self.class.cutoff_date) }
      }
    end
  end
end
