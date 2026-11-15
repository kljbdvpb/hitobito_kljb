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

  # Rollen, deren Label im Wagon-Locale definiert ist (Core-Rollen wie Event::Role::AssistantLeader
  # haben im Core-Locale teils identische Formen und sind nicht Gegenstand dieses Wagons).
  let(:wagon_keys) do
    file = HitobitoKljb::Wagon.root.join("config/locales/models.kljb.de.yml")
    YAML.load_file(file).dig("de", "activerecord", "models").keys
  end

  def check_plural(types)
    errors = []
    types.each do |type|
      plural = begin
        type.label_plural
      rescue => e
        errors << "#{type.sti_name}: #{e.class}"
        next
      end
      errors << "#{type.sti_name}: leer" if plural.blank?
      if wagon_keys.include?(type.model_name.i18n_key.to_s) && plural == type.label
        errors << "#{type.sti_name}: Plural == Singular (#{plural})"
      end
    end
    errors
  end

  it "liefert fuer jede Gruppenrolle ein Plural-Label ohne Exception (Wagon-Rollen: != Singular)" do
    expect(check_plural(group_role_types)).to eq([])
  end

  it "liefert fuer jede Event-Rolle ein Plural-Label ohne Exception (Wagon-Rollen: != Singular)" do
    expect(check_plural(event_role_types)).to eq([])
  end

  it "definiert fuer jede Rolle im Wagon-Locale one und other" do
    models = YAML.load_file(HitobitoKljb::Wagon.root.join("config/locales/models.kljb.de.yml"))
      .dig("de", "activerecord", "models")
    missing = models.select { |_, v| v.is_a?(Hash) && v["one"] && !v["other"] }.keys
    expect(missing).to eq([])
  end
end
