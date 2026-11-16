# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require "spec_helper"

# Core-Label fuer Event::Role::AssistantLeader ist "Leitung" (Singular und Plural, models.de.yml).
# Der Wagon ueberschreibt es mit "Co-Leitung"/"Co-Leitungen"; die Klasse bleibt unveraendert.
describe "Label Event::Role::AssistantLeader" do
  around { |example| I18n.with_locale(:de) { example.run } }

  it "heisst im Singular Co-Leitung" do
    expect(Event::Role::AssistantLeader.label).to eq "Co-Leitung"
  end

  it "heisst im Plural Co-Leitungen" do
    expect(Event::Role::AssistantLeader.label_plural).to eq "Co-Leitungen"
  end

  it "laesst die Hauptleitung unveraendert" do
    expect(Event::Role::Leader.label).to eq "Leitung"
  end
end
