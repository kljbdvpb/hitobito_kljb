# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require "spec_helper"

# Kurse sind abgeschaltet (Nutzerentscheidung 2026-11-19, docs/webtest-befunde-3.md):
# Kein Gruppentyp hat Event::Course in event_types, daher gibt es keinen Kurs-Layer und
# der Core (QualificationAbility#in_course_layer_with) erlaubt niemandem, Qualifikationen
# anzulegen oder zu loeschen. Bestehende Qualifikationen bleiben in der DB.
describe QualificationAbility do
  let(:person) { Fabricate("Group::Ortsgruppe::Mitglied", group: groups(:paderborn)).person }
  let(:qualification) do
    Qualification.new(person: person, qualification_kind: Fabricate(:qualification_kind),
                      start_at: Date.new(2020, 5, 1))
  end

  subject(:ability) { Ability.new(user.reload) }

  it "kein Gruppentyp hat Event-Typen, es gibt keine Kurs-Layer" do
    Group.all_types.each do |type|
      expect(type.event_types).to eq([]), "#{type} hat event_types #{type.event_types}"
    end
    expect(Group.course_types).to be_empty
  end

  {
    "IT-Support (layer_and_below_full im Diözesanverband)" => -> { people(:admin) },
    "Diözesanvorstand (layer_and_below_full)" => lambda {
      Fabricate("Group::DioezesanverbandVorstand::Vorstand", group: groups(:dioezesanvorstand)).person
    },
    "Büro-Verwaltungsleitung (layer_and_below_full)" => lambda {
      Fabricate("Group::DioezesanverbandBuero::Verwaltungsleitung", group: groups(:buero)).person
    },
    "Büro-Mitarbeiter (layer_full)" => lambda {
      Fabricate("Group::DioezesanverbandBuero::Mitarbeiter", group: groups(:buero)).person
    },
    "Regionalverbands-Vorstand (layer_and_below_full)" => lambda {
      Fabricate("Group::RegionalverbandVorstand::Vorsitz", group: groups(:vorstand_7)).person
    },
    "Ortsgruppen-Vorstand (layer_and_below_full)" => lambda {
      Fabricate("Group::OrtsgruppeVorstand::Vorsitz", group: groups(:paderborn_vorstand)).person
    },
    "Fördermitglied (keine Berechtigung)" => -> { people(:member) }
  }.each do |name, user_factory|
    context "#{name}" do
      let(:user) { instance_exec(&user_factory) }

      it "darf keine Qualifikation anlegen oder loeschen" do
        expect(ability).not_to be_able_to(:create, qualification)
        expect(ability).not_to be_able_to(:destroy, qualification)
      end
    end
  end

  context "Verwaltung der Qualifikationsarten (Admin)" do
    let(:user) { people(:admin) }

    it "ist ausgeblendet, solange es keine Kurs-Typen gibt (VariousAbility)" do
      expect(ability).not_to be_able_to(:index, QualificationKind)
      expect(ability).not_to be_able_to(:manage, Fabricate(:qualification_kind))
    end
  end
end
