# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

namespace :hitobito_kljb do
  namespace :orphan_groups do
    desc "Verwaiste Gruppen (parent_id/layer_group_id zeigt auf nicht existierende Gruppe, plus " \
         "Nachfahren) finden. Standard: Trockenlauf (nur IDs, Typen, Rollenzahlen); APPLY=1 " \
         "beendet aktive Rollen (end_on = gestern) und loescht die Gruppen weich (deleted_at). " \
         "Kein Hard-Delete, idempotent."
    task cleanup: :environment do
      apply = ENV["APPLY"] == "1"
      orphans = Kljb::OrphanGroups.new
      rows = orphans.rows

      puts "VERWAISTE GRUPPEN #{apply ? "APPLY" : "TROCKENLAUF"}"
      rows.each do |r|
        puts "GROUP id=#{r.id} type=#{r.type} aktive_rollen=#{r.active_roles} " \
             "beendete_rollen=#{r.ended_roles} kuenftige_rollen=#{r.future_roles}"
      end
      totals = orphans.totals(rows)
      puts "SUMME gruppen=#{totals[:groups]} aktive_rollen=#{totals[:active_roles]} " \
           "beendete_rollen=#{totals[:ended_roles]} kuenftige_rollen=#{totals[:future_roles]}"

      if apply
        result = orphans.apply!
        puts "ERGEBNIS gruppen_geloescht=#{result[:groups]} rollen_beendet=#{result[:roles_ended]}"
      else
        puts "Trockenlauf: nichts geschrieben. Mit APPLY=1 erneut ausfuehren."
      end
    end
  end
end
