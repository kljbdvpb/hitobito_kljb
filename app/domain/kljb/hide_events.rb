# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

# Anlaesse und Kurse sind in der KLJB-Instanz abgeschaltet (Nutzerentscheidung 2026-11-19,
# docs/webtest-befunde-3.md). Die Daten bleiben in der DB, nur die Oberflaeche blendet aus.
#
# Ueber `event_types = []` (Kljb::Group) verschwinden bereits der Gruppen-Reiter Anlaesse/
# Kurse (Sheet::Group) und der Hauptmenue-Punkt Kurse (Group.course_types leer). Nicht an
# event_types gekoppelt sind der Hauptmenue-Punkt Anlaesse (EventAbility list_available) und
# die Anmeldungen/Anmeldungs-Boxen im Personenprofil; dafuer sind diese beiden Overrides.
module Kljb
  module HideEvents
    HIDDEN_MAIN_NAV = %i[events courses].freeze

    # Admin-Menue: Kursarten, Kursart-Kategorien (VariousAbility: index fuer alle sichtbar)
    # und Qualifikationsarten.
    HIDDEN_ADMIN_MODELS = [Event::Kind, Event::KindCategory, QualificationKind].freeze

    # Entfernt Anlaesse/Kurse aus NavigationHelper::MAIN und die Kurs-Verwaltung aus dem
    # Admin-Menue (idempotent, to_prepare laeuft mehrfach). Leere Admin-Gruppen entfallen.
    def self.apply_main_nav!
      NavigationHelper::MAIN.reject! { |item| HIDDEN_MAIN_NAV.include?(item[:label]) }

      NavigationHelper::ADMIN_GROUPS.each_value do |group|
        group[:items].reject! { |item| HIDDEN_ADMIN_MODELS.include?(item.model) }
      end
      NavigationHelper::ADMIN_GROUPS.reject! { |_key, group| group[:items].empty? }
    end

    # Personenprofil (people/_attrs): keine Anmeldungen/Bewerbungen/Anlaesse in der Seitenleiste.
    module PersonDecorator
      def pending_applications
        []
      end

      def upcoming_participations_grouped
        {}
      end
    end
  end
end
