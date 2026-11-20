# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require 'spec_helper'

describe BoardMemberChecksController, type: :controller do
  let(:rv) { Fabricate(Group::Regionalverband.name.to_sym, parent: groups(:root)) }
  let(:og) { Fabricate(Group::Ortsgruppe.name.to_sym, parent: rv) }
  let(:vorstand) { Group::OrtsgruppeVorstand.find_by(parent_id: og.id) }
  let(:leiterrunde) { Group::OrtsgruppeLeiterrunde.find_by(parent_id: og.id) }
  let(:kontakte) { Group::OrtsgruppeKontakte.find_by(parent_id: og.id) }
  let(:user) { Fabricate(Group::OrtsgruppeVorstand::Vorsitz.name.to_sym, group: vorstand).person }

  let(:person) { Fabricate(:person, first_name: 'Ohne', last_name: 'Mitglied') }

  before do
    Fabricate(Group::OrtsgruppeVorstand::Mitglied.name.to_sym, group: vorstand, person: person)
    sign_in(user)
  end

  render_views

  # Layout bindet application.css ein, Assets sind in der Wagon-CI nicht gebaut.
  before { allow(controller).to receive(:_layout).and_return(nil) }

  it 'listet Vorstandspersonen ohne Mitgliedsrolle' do
    get :index, params: { group_id: vorstand.id }

    expect(response).to be_successful
    expect(response.body).to include('Ohne Mitglied')
  end

  it 'listet Personen mit Mitgliedsrolle nicht' do
    Fabricate(Group::Ortsgruppe::Mitglied.name.to_sym, group: og, person: person)
    get :index, params: { group_id: vorstand.id }

    expect(response.body).not_to include('Ohne Mitglied')
  end

  it 'liefert 404 fuer nicht betroffene Gruppen' do
    expect { get :index, params: { group_id: og.id } }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'verweist auf die Duplikate-Liste der Ortsgruppe' do
    get :index, params: { group_id: vorstand.id }

    expect(response.body).to include(group_person_duplicates_path(og))
  end

  it 'zaehlt eine Mitgliedsrolle mit start_on in der Zukunft als Mitglied' do
    Fabricate(Group::Ortsgruppe::Mitglied.name.to_sym, group: og, person: person,
                                                         start_on: Date.current + 1.month)
    get :index, params: { group_id: vorstand.id }

    expect(response.body).not_to include('Ohne Mitglied')
  end

  it 'verweigert dem Vorsitz einer anderen Ortsgruppe (Layer-Grenze)' do
    og2 = Fabricate(Group::Ortsgruppe.name.to_sym, parent: rv)
    vorstand2 = Group::OrtsgruppeVorstand.find_by(parent_id: og2.id)
    sign_in(Fabricate(Group::OrtsgruppeVorstand::Vorsitz.name.to_sym, group: vorstand2).person)

    expect { get :index, params: { group_id: vorstand.id } }.to raise_error(CanCan::AccessDenied)
  end

  it 'verweigert Vorstands-Mitgliedern mit nur layer_full' do
    sign_in(Fabricate(Group::OrtsgruppeVorstand::Mitglied.name.to_sym, group: vorstand).person)

    expect { get :index, params: { group_id: vorstand.id } }.to raise_error(CanCan::AccessDenied)
  end

  it 'verweigert Personen ohne Berechtigung' do
    sign_in(Fabricate(Group::OrtsgruppeLeiterrunde::Leiter.name.to_sym, group: leiterrunde).person)

    expect { get :index, params: { group_id: vorstand.id } }.to raise_error(CanCan::AccessDenied)
  end

  context 'verwaiste Gruppe (layer_group_id zeigt ins Leere)' do
    before do
      vorstand.update_columns(layer_group_id: Group.unscoped.maximum(:id) + 1000)
    end

    it 'liefert 404 statt NoMethodError' do
      expect { get :index, params: { group_id: vorstand.id } }
        .to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
