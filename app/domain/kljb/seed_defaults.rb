# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

# Gezieltes Seeden nach Migration/Update (Ersatz fuer `db:seed`, das auch root.rb ausfuehrt
# und die Person mit Settings.root_email ueberschreibt, sowie Orte und Kontaktkategorien).
#
# (a) Core db/seeds/custom_contents.rb: legt fehlende CustomContents (Keys) und fehlende
#     Uebersetzungen an. Vorhandene Texte (label/subject/body) werden nie ueberschrieben;
#     bei vorhandenen Keys werden nur die Platzhalter-Spalten auf Core-Werte gesetzt.
# (b) OrderTableSeeder: baut group_type_orders, role_type_orders und event_role_type_orders
#     aus den Typ-Klassen neu auf (TRUNCATE + INSERT, nicht atomar: nur vor App-Start bzw.
#     im Wartungsfenster ausfuehren). Der Core sortiert per INNER JOIN darauf.
module Kljb
  class SeedDefaults
    Result = Struct.new(:custom_contents_before, :custom_contents_after, :custom_contents_soll,
      :group_type_orders, :role_type_orders, :event_role_type_orders,
      :soll_group_types, :soll_role_types, :soll_event_role_types, keyword_init: true) do
      def ok?
        custom_contents_after >= custom_contents_soll &&
          group_type_orders == soll_group_types &&
          role_type_orders == soll_role_types &&
          event_role_type_orders == soll_event_role_types
      end
    end

    def run
      before = ::CustomContent.count
      soll = seed_custom_contents
      seed_order_tables
      result(before, soll)
    end

    private

    def seeds_dir
      Rails.root.join("db", "seeds")
    end

    # Soll = Keys in der Core-Seed-Datei; custom_dashboard_page_content nur bei aktivem FeatureGate.
    def seed_custom_contents
      src = File.read(seeds_dir.join("custom_contents.rb"))
      gated = FeatureGate.enabled?("custom_dashboard_page") ? 0 : 1
      quiet = SeedFu.quiet
      SeedFu.quiet = true
      SeedFu.seed([seeds_dir.to_s], /custom_contents\.rb\z/)
      SeedFu.quiet = quiet
      src.scan(/\bkey:/).size - gated
    end

    def seed_order_tables
      # Alle Typ-Klassen laden, sonst fehlen z. B. Event::Course und dessen Rollen
      # in Event.all_types (Rake laedt nicht eager).
      Rails.application.eager_load!
      require seeds_dir.join("support", "order_table_seeder").to_s
      OrderTableSeeder.new.seed
    end

    def result(before, soll)
      Result.new(
        custom_contents_before: before, custom_contents_after: ::CustomContent.count,
        custom_contents_soll: soll,
        group_type_orders: GroupTypeOrder.count, role_type_orders: RoleTypeOrder.count,
        event_role_type_orders: EventRoleTypeOrder.count,
        soll_group_types: ::Group.all_types.size, soll_role_types: ::Role.all_types.size,
        soll_event_role_types: ::Event.all_types.sum { |t| t.role_types.size }
      )
    end
  end
end
