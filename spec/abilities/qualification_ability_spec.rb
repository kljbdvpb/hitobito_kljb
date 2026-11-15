# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require "spec_helper"

# Qualifikationen werden ohne Kursteilnahme direkt bei der Person erfasst
# (QualificationsController, Personenseite). Das Recht dazu haengt im Core davon ab, dass
# der Layer des Benutzers Event::Course in event_types hat. Im Wagon gilt das nur fuer
# den Diözesanverband (Group::Dioezesanverband).
describe QualificationAbility do
  let(:person) { Fabricate("Group::Ortsgruppe::Mitglied", group: groups(:paderborn)).person }
  let(:qualification) do
    Qualification.new(person: person, qualification_kind: Fabricate(:qualification_kind),
                      start_at: Date.new(2020, 5, 1))
  end

  subject(:ability) { Ability.new(user.reload) }

  it "Diözesanverband hat den Kurs-Typ, Regionalverband und Ortsgruppe nicht" do
    expect(Group::Dioezesanverband.event_types).to eq([Event, Event::Course])
    expect(Group::Regionalverband.event_types).to eq([Event])
    expect(Group::Ortsgruppe.event_types).to eq([Event])
    expect(Group.course_types).to include(Group::Dioezesanverband)
    expect(Group.course_types).not_to include(Group::Ortsgruppe, Group::Regionalverband)
  end

  context "mit layer_and_below_full im Diözesanverband (IT-Support)" do
    let(:user) { people(:admin) }

    it "darf Qualifikation fuer Person in Ortsgruppe anlegen und loeschen (ohne Kurs)" do
      expect(ability).to be_able_to(:create, qualification)
      expect(ability).to be_able_to(:destroy, qualification)
    end
  end

  context "mit layer_and_below_full im Diözesanvorstand" do
    let(:user) { Fabricate("Group::DioezesanverbandVorstand::Vorstand", group: groups(:dioezesanvorstand)).person }

    it "darf Qualifikation fuer Person in Ortsgruppe anlegen" do
      expect(ability).to be_able_to(:create, qualification)
    end
  end

  context "ohne Berechtigung im Diözesanverband (Fördermitglied)" do
    let(:user) { people(:member) }

    it "darf keine Qualifikation anlegen oder loeschen" do
      expect(ability).not_to be_able_to(:create, qualification)
      expect(ability).not_to be_able_to(:destroy, qualification)
    end
  end

  context "mit layer_and_below_full nur in der eigenen Ortsgruppe" do
    let(:user) { Fabricate("Group::OrtsgruppeVorstand::Vorsitz", group: groups(:paderborn_vorstand)).person }

    it "darf weiterhin keine Qualifikation anlegen (Ortsgruppe ist kein Kurs-Layer)" do
      expect(ability).not_to be_able_to(:create, qualification)
    end
  end

  context "Diözesanvorstand: destroy" do
    let(:user) { Fabricate("Group::DioezesanverbandVorstand::Vorstand", group: groups(:dioezesanvorstand)).person }

    it "darf Qualifikation loeschen" do
      expect(ability).to be_able_to(:destroy, qualification)
    end
  end

  context "Büro (Verwaltungsleitung, layer_and_below_full)" do
    let(:user) { Fabricate("Group::DioezesanverbandBuero::Verwaltungsleitung", group: groups(:buero)).person }

    it "darf Qualifikation anlegen und loeschen" do
      expect(ability).to be_able_to(:create, qualification)
      expect(ability).to be_able_to(:destroy, qualification)
    end
  end

  context "Regionalverbands-Vorstand (layer_and_below_full im Regionalverband)" do
    let(:user) { Fabricate("Group::RegionalverbandVorstand::Vorsitz", group: groups(:vorstand_7)).person }

    it "darf weder anlegen noch loeschen (Regionalverband ist kein Kurs-Layer)" do
      expect(ability).not_to be_able_to(:create, qualification)
      expect(ability).not_to be_able_to(:destroy, qualification)
    end
  end

  context "Büro-Mitarbeiter (nur layer_full im Diözesanverband)" do
    let(:user) { Fabricate("Group::DioezesanverbandBuero::Mitarbeiter", group: groups(:buero)).person }
    let(:dv_person) { Fabricate("Group::Dioezesanverband::Foerdermitglied", group: groups(:root)).person }
    let(:dv_qualification) do
      Qualification.new(person: dv_person, qualification_kind: Fabricate(:qualification_kind),
                        start_at: Date.new(2020, 5, 1))
    end

    it "darf nicht fuer Personen in der Ortsgruppe" do
      expect(ability).not_to be_able_to(:create, qualification)
      expect(ability).not_to be_able_to(:destroy, qualification)
    end

    # Rot ohne den event_types-Fix: layer_full greift nur, wenn der Layer des Benutzers
    # Event::Course in event_types hat (Core QualificationAbility#in_course_layer_with).
    # Ohne `Group::Dioezesanverband.event_types = [Event, Event::Course]` waere das hier nein.
    it "darf fuer Personen im Diözesanverband-Layer anlegen und loeschen" do
      expect(ability).to be_able_to(:create, dv_qualification)
      expect(ability).to be_able_to(:destroy, dv_qualification)
    end
  end
end
