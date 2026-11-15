# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require "spec_helper"

describe Kljb::SeedDefaults do
  let(:key) { Person::LoginMailer::CONTENT_LOGIN }

  def seed
    described_class.new.run
  end

  it "legt einen fehlenden CustomContent-Key an" do
    CustomContent.where(key: key).destroy_all
    expect { seed }.to change { CustomContent.where(key: key).count }.from(0).to(1)
  end

  it "ueberschreibt eine vorhandene Uebersetzung nicht" do
    seed
    content = CustomContent.find_by(key: key)
    translation = content.translations.find_by(locale: "de") || content.translations.build(locale: "de")
    translation.update!(label: "Eigenes Label", subject: "Eigener Betreff", body: "Eigener Text {login-url}")

    seed

    translation = CustomContent.find_by(key: key).translations.find_by(locale: "de")
    expect(translation.label).to eq("Eigenes Label")
    expect(translation.subject).to eq("Eigener Betreff")
    expect(translation.body.to_s).to include("Eigener Text")
  end

  it "baut die Order-Tabellen auf: Anzahl = Anzahl der Typen" do
    [GroupTypeOrder, RoleTypeOrder, EventRoleTypeOrder].each(&:delete_all)

    result = seed

    expect(GroupTypeOrder.count).to eq(Group.all_types.size)
    expect(RoleTypeOrder.count).to eq(Role.all_types.size)
    expect(EventRoleTypeOrder.count).to eq(Event.all_types.sum { |t| t.role_types.size })
    expect(GroupTypeOrder.count).to be > 0
    expect(result).to be_ok
    expect(CustomContent.count).to be >= result.custom_contents_soll
  end

  it "ist idempotent (zweiter Lauf aendert die Anzahlen nicht)" do
    first = seed
    second = seed
    expect(second.custom_contents_after).to eq(first.custom_contents_after)
    expect(second.group_type_orders).to eq(first.group_type_orders)
  end
end
