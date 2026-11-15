# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

namespace :hitobito_kljb do
  desc "Fehlende Core-CustomContents anlegen (nicht ueberschreibend) und Order-Tabellen neu aufbauen; " \
       "nach db:migrate/wagon:migrate und vor App-Start ausfuehren. Exit 1, wenn das Soll nicht erreicht ist."
  task seed_defaults: :environment do
    r = Kljb::SeedDefaults.new.run
    puts "SEED custom_contents vorher=#{r.custom_contents_before} nachher=#{r.custom_contents_after} " \
         "soll=#{r.custom_contents_soll}"
    puts "SEED order_tables group=#{r.group_type_orders}/#{r.soll_group_types} " \
         "role=#{r.role_type_orders}/#{r.soll_role_types} " \
         "event_role=#{r.event_role_type_orders}/#{r.soll_event_role_types}"
    abort "SEED GATE ROT: Soll nicht erreicht" unless r.ok?
    puts "SEED GATE OK"
  end
end
