# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require 'spec_helper'

describe Kljb::BoardMembership do
  let(:rv) { Fabricate(Group::Regionalverband.name.to_sym, parent: groups(:root)) }
  let(:og) { Fabricate(Group::Ortsgruppe.name.to_sym, parent: rv) }
  let(:vorstand) { Group::OrtsgruppeVorstand.find_by(parent_id: og.id) }
  let(:leiterrunde) { Group::OrtsgruppeLeiterrunde.find_by(parent_id: og.id) }
  let(:kontakte) { Group::OrtsgruppeKontakte.find_by(parent_id: og.id) }
  let(:user) { Fabricate(Group::OrtsgruppeVorstand::Vorsitz.name.to_sym, group: vorstand).person }

  let(:person) { Fabricate(:person) }

  context '.no_new_person?' do
    it 'gilt fuer Vorstand und Leiterrunde der Ortsgruppe und den RV-Vorstand' do
      expect(described_class.no_new_person?(vorstand)).to be true
      expect(described_class.no_new_person?(leiterrunde)).to be true
      expect(described_class.no_new_person?(Group::RegionalverbandVorstand.find_by(parent_id: rv.id))).to be true
    end

    it 'gilt nicht fuer Ortsgruppe, Kontakte, Regionalverband und Diözesanverband' do
      [og, kontakte, rv, groups(:root), groups(:dioezesanvorstand)].each do |group|
        expect(described_class.no_new_person?(group)).to be(false), group.class.name
      end
    end

    it 'erkennt auch dekorierte Gruppen' do
      expect(described_class.no_new_person?(vorstand.decorate)).to be true
    end
  end

  context 'verwaiste Gruppe (Layer fehlt)' do
    # Rolle zuerst anlegen (Validierungen brauchen den Layer), dann Layer verschwinden lassen
    let!(:role) { Fabricate(Group::OrtsgruppeVorstand::Vorsitz.name.to_sym, group: vorstand, person: person) }

    # Altdaten: layer_group_id zeigt auf eine nicht existierende Gruppe (ohne Callbacks)
    before do
      vorstand.update_columns(layer_group_id: ::Group.unscoped.maximum(:id) + 1000)
      vorstand.reload
      role.reload
    end

    it 'hat tatsaechlich keinen Layer' do
      expect(vorstand.layer_group).to be_nil
    end

    it 'without_membership liefert keine Personen statt NoMethodError' do
      expect(described_class.without_membership(vorstand).to_a).to eq []
    end

    it 'membership_missing? ist false statt NoMethodError' do
      expect(described_class.membership_missing?(role)).to be false
    end
  end

  context '.without_membership' do
    it 'liefert Personen ohne Mitglied-Rolle in der Ortsgruppe' do
      Fabricate(Group::OrtsgruppeVorstand::Vorsitz.name.to_sym, group: vorstand, person: person)
      expect(described_class.without_membership(vorstand)).to include(person)
    end

    it 'liefert keine Personen mit Rolle Mitglied in der Ortsgruppe, aber Foerdermitglieder' do
      Fabricate(Group::Ortsgruppe::Mitglied.name.to_sym, group: og, person: person)
      Fabricate(Group::OrtsgruppeVorstand::Vorsitz.name.to_sym, group: vorstand, person: person)
      other = Fabricate(:person)
      Fabricate(Group::Ortsgruppe::Foerdermitglied.name.to_sym, group: og, person: other)
      Fabricate(Group::OrtsgruppeVorstand::Mitglied.name.to_sym, group: vorstand, person: other)

      expect(described_class.without_membership(vorstand)).not_to include(person)
      expect(described_class.without_membership(vorstand)).to include(other)
    end

    it 'wertet eine Mitgliedsrolle mit start_on in der Zukunft als Mitglied' do
      Fabricate(Group::Ortsgruppe::Mitglied.name.to_sym, group: og, person: person,
                                                           start_on: Date.current + 1.month)
      Fabricate(Group::OrtsgruppeVorstand::Vorsitz.name.to_sym, group: vorstand, person: person)
      expect(described_class.without_membership(vorstand)).not_to include(person)
    end

    it 'nimmt die Geistliche Leitung aus' do
      Fabricate(Group::OrtsgruppeVorstand::Geist.name.to_sym, group: vorstand, person: person)
      expect(described_class.without_membership(vorstand)).not_to include(person)
    end

    it 'liefert leer fuer nicht betroffene Gruppen' do
      expect(described_class.without_membership(og)).to be_empty
    end
  end

  context '.membership_missing?' do
    it 'ist wahr fuer Vorstandsrolle ohne Mitgliedsrolle, falsch mit Mitgliedsrolle oder als Geist' do
      role = Fabricate(Group::OrtsgruppeVorstand::Vorsitz.name.to_sym, group: vorstand, person: person)
      expect(described_class.membership_missing?(role)).to be true

      Fabricate(Group::Ortsgruppe::Mitglied.name.to_sym, group: og, person: person)
      expect(described_class.membership_missing?(role)).to be false

      geist = Fabricate(Group::OrtsgruppeVorstand::Geist.name.to_sym, group: vorstand, person: Fabricate(:person))
      expect(described_class.membership_missing?(geist)).to be false
    end
  end
end
