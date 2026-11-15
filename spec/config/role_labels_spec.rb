# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require "spec_helper"

# Core 2.11.5 ruft Role.label_plural bzw. Event::Role.label_plural mit count: 2 auf
# (z. B. events/new -> Fragen-Sichtbarkeit). Fehlt im Wagon-Locale `other:`, wirft I18n
# InvalidPluralizationData (500 auf Event-Formularen). Diese Specs sichern alle Typen ab.
describe "Rollen-Labels (Plural)" do
  let(:group_role_types) { Role.all_types }
  let(:event_role_types) do
    event_types = ([Event, Event::Course] + Event.all_types).uniq
    (event_types.flat_map(&:role_types) + [Event::Role::Teamer]).uniq
  end

  it "kennt Gruppenrollen und Event-Rollen des Wagons" do
    expect(group_role_types).to include(Group::Ortsgruppe::Mitglied, Group::Dioezesanverband::ItSupport)
    expect(event_role_types).to include(Event::Role::Teamer, Event::Role::Leader)
  end

  it "liefert fuer jede Gruppenrolle ein Plural-Label ohne Exception, das vom Singular abweicht" do
    group_role_types.each do |type|
      plural = nil
      expect { plural = type.label_plural }.not_to raise_error, "#{type.sti_name} ohne other:"
      expect(plural).to be_present
      expect(plural).not_to eq(type.label), "#{type.sti_name}: Plural == Singular (#{plural})"
    end
  end

  it "liefert fuer jede Event-Rolle ein Plural-Label ohne Exception, das vom Singular abweicht" do
    event_role_types.each do |type|
      plural = nil
      expect { plural = type.label_plural }.not_to raise_error, "#{type.sti_name} ohne other:"
      expect(plural).to be_present
      expect(plural).not_to eq(type.label), "#{type.sti_name}: Plural == Singular (#{plural})"
    end
  end
end
