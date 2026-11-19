# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

# Quicksearch-Ausklappmenue (/full.json): Gruppen vor Personen.
#
# Hintergrund: Der Core liefert Personen, Gruppen, Events. Das Autocomplete-JS kappt
# clientseitig bei 15 Eintraegen (remote_autocomplete.js, maxResults). Bei einer Suche
# nach einem Ortsnamen stehen dadurch zig Personen vor der einen Ortsgruppe, die Gruppe
# faellt aus der Liste (Befund webtest-befunde-2).
#
# Reihenfolge hier: Gruppen, Personen, Events, Rechnungen (Events relativ zu Personen
# wie im Core). Die Gruppen werden auf MAX_GROUPS begrenzt, damit bei sehr vielen
# Gruppentreffern (z. B. "Vorstand") innerhalb der 15 Eintraege noch Personen sichtbar
# bleiben. Gruppentreffer sind normalerweise wenige.
#
# Nur die JSON-Ausgabe (results_with_separator wird nur von query_json_results benutzt).
# Die HTML-Ergebnisseite (/full), Suche und Berechtigungen (Search-Strategies mit
# Readables-Ability) bleiben unveraendert.
module Kljb
  module QuicksearchGroupsFirst
    MAX_GROUPS = 10

    # Der Core-JS setzt das Label als HTML ein; die Klasse erlaubt es dem Wagon-SCSS, die
    # Trennzeile nicht klickbar zu machen (Klick fuehrte sonst nach /undefined/undefined).
    SEPARATOR_LABEL = '<span class="quicksearch-separator">' + ('—' * 20) + '</span>'

    private

    def results_with_separator
      sets = [Array(@groups).first(MAX_GROUPS), @people, @events, @invoices].compact_blank
      sets.inject do |memo, set|
        memo + [{label: SEPARATOR_LABEL}] + set
      end
    end
  end
end
