# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require 'spec_helper'

describe Kljb::BoardMembership, 'Fachentscheidungen 2026-11-19' do
  let(:rv) { Fabricate(Group::Regionalverband.name.to_sym, parent: groups(:root)) }
  let(:og) { Fabricate(Group::Ortsgruppe.name.to_sym, parent: rv) }
  let(:rv2) { Fabricate(Group::Regionalverband.name.to_sym, parent: groups(:root)) }
  let(:og2) { Fabricate(Group::Ortsgruppe.name.to_sym, parent: rv2) }
  let(:vorstand) { Group::OrtsgruppeVorstand.find_by(parent_id: og.id) }
  let(:rv_vorstand) { Group::RegionalverbandVorstand.find_by(parent_id: rv.id) }
  let(:person) { Fabricate(:person) }

  describe 'Ortsgruppen-Vorstand' do
    before { Fabricate(Group::OrtsgruppeVorstand::Mitglied.name.to_sym, group: vorstand, person: person) }

    it 'zaehlt Foerdermitglied NICHT als Mitglied' do
      Fabricate(Group::Ortsgruppe::Foerdermitglied.name.to_sym, group: og, person: person)

      expect(described_class.without_membership(vorstand)).to include(person)
    end

    it 'zaehlt Mitglied (auch mit Start in der Zukunft) als Mitglied' do
      Fabricate(Group::Ortsgruppe::Mitglied.name.to_sym, group: og, person: person,
                                                           start_on: Date.current + 1.month)

      expect(described_class.without_membership(vorstand)).not_to include(person)
    end

    it 'nimmt Geist aus dem Bericht aus' do
      geist = Fabricate(:person)
      Fabricate(Group::OrtsgruppeVorstand::Geist.name.to_sym, group: vorstand, person: geist)

      expect(described_class.without_membership(vorstand)).not_to include(geist)
    end
  end

  describe 'Regionalverband-Vorstand' do
    before { Fabricate(Group::RegionalverbandVorstand::Mitglied.name.to_sym, group: rv_vorstand, person: person) }

    it 'sperrt neue Personen ausser fuer Geist' do
      expect(described_class.new_person_blocked?(rv_vorstand, Group::RegionalverbandVorstand::Mitglied)).to be true
      expect(described_class.new_person_blocked?(rv_vorstand, 'Group::RegionalverbandVorstand::Geist')).to be false
    end

    it 'meldet Person ohne Mitgliedsrolle' do
      expect(described_class.without_membership(rv_vorstand)).to include(person)
    end

    it 'zaehlt Mitglied in einer Ortsgruppe des eigenen RV' do
      Fabricate(Group::Ortsgruppe::Mitglied.name.to_sym, group: og, person: person)

      expect(described_class.without_membership(rv_vorstand)).not_to include(person)
    end

    it 'zaehlt Mitglied mit Start in der Zukunft' do
      Fabricate(Group::Ortsgruppe::Mitglied.name.to_sym, group: og, person: person,
                                                           start_on: Date.current + 1.month)

      expect(described_class.without_membership(rv_vorstand)).not_to include(person)
    end

    it 'zaehlt Mitglied in einer Ortsgruppe eines FREMDEN RV nicht' do
      Fabricate(Group::Ortsgruppe::Mitglied.name.to_sym, group: og2, person: person)

      expect(described_class.without_membership(rv_vorstand)).to include(person)
    end

    it 'zaehlt Foerdermitglied in der Ortsgruppe nicht' do
      Fabricate(Group::Ortsgruppe::Foerdermitglied.name.to_sym, group: og, person: person)

      expect(described_class.without_membership(rv_vorstand)).to include(person)
    end

    it 'nimmt Geist aus dem Bericht aus' do
      geist = Fabricate(:person)
      Fabricate(Group::RegionalverbandVorstand::Geist.name.to_sym, group: rv_vorstand, person: geist)

      expect(described_class.without_membership(rv_vorstand)).not_to include(geist)
    end
  end

  it 'laesst die Ortsgruppen-AG ungesperrt' do
    ag = Fabricate(Group::OrtsgruppeAg.name.to_sym, parent: og)
    expect(described_class.no_new_person?(ag)).to be false
  end

  describe 'archivierte Mitgliedschaften' do
    before { Fabricate(Group::OrtsgruppeVorstand::Mitglied.name.to_sym, group: vorstand, person: person) }

    it 'zaehlt eine archivierte Mitgliedsrolle in der Ortsgruppe nicht' do
      role = Fabricate(Group::Ortsgruppe::Mitglied.name.to_sym, group: og, person: person)
      role.update_column(:archived_at, 1.day.ago)

      expect(described_class.without_membership(vorstand)).to include(person)
    end

    it 'zaehlt im RV-Vorstand keine Mitgliedschaft in einer archivierten Ortsgruppe' do
      Fabricate(Group::RegionalverbandVorstand::Mitglied.name.to_sym, group: rv_vorstand, person: person)
      role = Fabricate(Group::Ortsgruppe::Mitglied.name.to_sym, group: og, person: person)
      og.update_column(:archived_at, 1.day.ago)
      role.update_column(:archived_at, 1.day.ago)

      expect(described_class.without_membership(rv_vorstand)).to include(person)
    end
  end

  describe 'Rollenbezeichnung der Ausnahme' do
    it 'kommt aus dem Rollen-Label, nicht vorhanden in der Leiterrunde' do
      expect(described_class.exempt_role_label(vorstand)).to eq('Geistliche Verbandsleitung')
      expect(described_class.exempt_role_label(Group::OrtsgruppeLeiterrunde.find_by(parent_id: og.id))).to be_nil
    end
  end
end
