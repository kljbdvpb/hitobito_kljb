# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require "spec_helper"

describe Kljb::HideEvents do
  it "Hauptmenue enthaelt weder Anlaesse noch Kurse" do
    labels = NavigationHelper::MAIN.map { |item| item[:label] }
    expect(labels).to include(:groups)
    expect(labels).not_to include(:events, :courses)
  end

  it "apply_main_nav! ist idempotent" do
    expect { described_class.apply_main_nav! }.not_to change { NavigationHelper::MAIN.size }
  end

  it "Gruppen-Reiter Anlaesse und Kurse werden nicht angezeigt" do
    group = groups(:paderborn)
    expect(group.event_types).to be_empty
    expect(group.event_types.include?(::Event)).to be(false)
    expect(group.event_types.include?(::Event::Course)).to be(false)
  end

  context "Personenprofil" do
    let(:person) { people(:admin) }
    let(:decorated) { PersonDecorator.new(person) }

    it "zeigt keine Anmeldungen und Bewerbungen" do
      expect(decorated.upcoming_participations_grouped).to eq({})
      expect(decorated.pending_applications).to eq([])
    end
  end
end
