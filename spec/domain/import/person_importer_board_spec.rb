# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require 'spec_helper'

describe Import::PersonImporter do
  let(:rv) { Fabricate(Group::Regionalverband.name.to_sym, parent: groups(:root)) }
  let(:og) { Fabricate(Group::Ortsgruppe.name.to_sym, parent: rv) }
  let(:vorstand) { Group::OrtsgruppeVorstand.find_by(parent_id: og.id) }
  let(:leiterrunde) { Group::OrtsgruppeLeiterrunde.find_by(parent_id: og.id) }
  let(:kontakte) { Group::OrtsgruppeKontakte.find_by(parent_id: og.id) }
  let(:user) { Fabricate(Group::OrtsgruppeVorstand::Vorsitz.name.to_sym, group: vorstand).person }

  let(:ability) { Ability.new(user) }

  def import(group, role_type, rows)
    importer = described_class.new(rows, group, role_type)
    importer.user_ability = ability
    importer
  end

  it 'meldet Zeilen mit neuer Person im Vorstand als fehlerhaft und legt nichts an' do
    importer = import(vorstand, Group::OrtsgruppeVorstand::Mitglied,
                      [{ first_name: 'Neu', last_name: 'Person', email: 'neu.import@example.com' }])

    expect { importer.import }.not_to change { Person.count }
    expect(importer.failure_count).to eq(1)
    expect(importer.errors.join).to include('zuerst als Mitglied')
  end

  it 'legt im Vorstand eine neue Person an, wenn die Rolle Geist ist' do
    importer = import(vorstand, Group::OrtsgruppeVorstand::Geist,
                      [{ first_name: 'Neu', last_name: 'Geist', email: 'neu.geist@example.com' }])

    expect { importer.import }.to change { Person.count }.by(1)
    expect(importer.failure_count).to eq(0)
  end

  it 'meldet Zeilen mit neuer Person im RV-Vorstand als fehlerhaft' do
    rv_vorstand = Group::RegionalverbandVorstand.find_by(parent_id: rv.id)
    importer = import(rv_vorstand, Group::RegionalverbandVorstand::Mitglied,
                      [{ first_name: 'Neu', last_name: 'Person', email: 'neu.rv@example.com' }])

    expect { importer.import }.not_to change { Person.count }
    expect(importer.failure_count).to eq(1)
  end

  it 'legt im RV-Vorstand eine neue Person an, wenn die Rolle Geist ist' do
    rv_vorstand = Group::RegionalverbandVorstand.find_by(parent_id: rv.id)
    importer = import(rv_vorstand, Group::RegionalverbandVorstand::Geist,
                      [{ first_name: 'Neu', last_name: 'Geist', email: 'neu.rvgeist@example.com' }])

    expect { importer.import }.to change { Person.count }.by(1)
  end

  it 'ergaenzt in der Ortsgruppe eine neue Person wie bisher' do
    importer = import(og, Group::Ortsgruppe::Mitglied,
                      [{ first_name: 'Neu', last_name: 'Person', email: 'neu.import@example.com' }])

    expect { importer.import }.to change { Person.count }.by(1)
    expect(importer.failure_count).to eq(0)
  end

  it 'ergaenzt im Vorstand die Rolle bei einer von der Dublettenerkennung gefundenen Person' do
    person = Fabricate(:person, first_name: 'Vor', last_name: 'Handen', email: 'vorhanden@example.com')
    Fabricate(Group::Ortsgruppe::Mitglied.name.to_sym, group: og, person: person)
    importer = import(vorstand, Group::OrtsgruppeVorstand::Mitglied,
                      [{ first_name: 'Vor', last_name: 'Handen', email: 'vorhanden@example.com' }])

    expect { importer.import }.to change { Role.where(group_id: vorstand.id, person_id: person.id).count }.by(1)
    expect(importer.failure_count).to eq(0)
  end
end
