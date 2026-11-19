# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

# Gruppenexport des Wagons: Mitgliederzahlen der jaehrlichen Zaehlung (Stichtag 01.09.) als
# Spalten, Gesamtzahl je Gruppe und eine Summenzeile am Ende (CSV und XLSX, gleiche Klasse).
module Kljb::Export::Tabular::Groups::List
  # Gespeicherte Spalten (AddMemberCountsToGroups, AddAgeGroupCountsToGroups)
  MEMBER_COUNT_ATTRS = %i[members_normal members_discounted].freeze
  AGE_COUNT_ATTRS = %i[members_under_14 members_from_14 members_up_to_27
    members_without_birthday].freeze
  # Spalten direkt hinter members_discounted: abgeleitete Gesamtzahl, dann Altersgruppen
  ADDED_ATTRS = ([:members_total] + AGE_COUNT_ATTRS).freeze
  # Zahlenspalten, die in der Summenzeile addiert werden
  SUM_ATTRS = (MEMBER_COUNT_ATTRS + ADDED_ATTRS + [:member_count]).freeze
  SUM_LABEL_ATTR = :name

  def attributes
    attrs = (super + MEMBER_COUNT_ATTRS).uniq - ADDED_ATTRS
    attrs.insert(attrs.index(:members_discounted) + 1, *ADDED_ATTRS)
  end

  # Wie im Core, plus Summenzeile als letzte Zeile (auch fuer den Enumerator ohne Block).
  def data_rows(format = nil)
    return enum_for(:data_rows, format) unless block_given?

    sums = Hash.new(0)
    super do |row|
      attributes.zip(row).each { |attr, value| sums[attr] += value.to_i if SUM_ATTRS.include?(attr) }
      yield row
    end
    yield sum_row(sums)
  end

  private

  def sum_row(sums)
    attributes.map do |attr|
      if attr == SUM_LABEL_ATTR
        I18n.t("export.tabular.groups.list.sum", default: "Summe")
      elsif SUM_ATTRS.include?(attr)
        sums[attr]
      end
    end
  end
end
