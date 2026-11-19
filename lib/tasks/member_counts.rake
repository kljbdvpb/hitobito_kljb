# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

namespace :hitobito_kljb do
  namespace :member_counts do
    desc "Altersspalten (u14/ab 14/bis 27/ohne Geburtsdatum) fuer den letzten Stichtag aus der " \
         "Rollen-Historie nachtragen. Schreibt NUR diese Spalten, nie members_normal/" \
         "members_discounted. Standard: Trockenlauf (nur Ausgabe); APPLY=1 schreibt; " \
         "FORCE=1 ueberschreibt bereits gefuellte Altersspalten; STICHTAG=YYYY-MM-DD optional."
    task backfill_age_groups: :environment do
      apply = ENV["APPLY"] == "1"
      force = ENV["FORCE"] == "1"
      date = Groups::MemberPaymentStatus.cutoff_date
      date = Date.iso8601(ENV["STICHTAG"]) if ENV["STICHTAG"].present?
      attrs = Groups::MemberPaymentStatus::AGE_ATTRIBUTES

      puts "BACKFILL Altersgruppen Stichtag=#{date} #{apply ? "APPLY" : "TROCKENLAUF"}"
      sums = Hash.new(0)
      deviations = 0
      Group::Ortsgruppe.find_each do |group|
        if !force && attrs.any? { |a| group.public_send(a) }
          puts "SKIP group=#{group.id} Altersspalten bereits gefuellt (FORCE=1 zum Ueberschreiben)"
          next
        end

        status = Groups::MemberPaymentStatus.new(group)
        values = if apply
          status.backfill_age_attributes!(at: date)
        else
          status.age_attributes(on: date, people: status.members_at(date))
        end
        total = values.values_at(:members_under_14, :members_from_14, :members_without_birthday).sum
        stored = if group.members_normal.nil? && group.members_discounted.nil?
          nil
        else
          group.members_normal.to_i + group.members_discounted.to_i
        end
        deviation = stored && stored != total
        deviations += 1 if deviation
        attrs.each { |a| sums[a] += values[a] }
        puts "GROUP id=#{group.id} rekonstruiert=#{total} gespeichert=#{stored.inspect}" \
             "#{" ABWEICHUNG" if deviation} " + attrs.map { |a| "#{a}=#{values[a]}" }.join(" ")
      end
      puts "SUMME " + attrs.map { |a| "#{a}=#{sums[a]}" }.join(" ")
      puts "ABWEICHUNGEN (rekonstruiert != members_normal+members_discounted): #{deviations}"
      puts "Trockenlauf: nichts geschrieben. Mit APPLY=1 erneut ausfuehren." unless apply
    end
  end
end
