# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require 'spec_helper'

describe PeopleController, type: :controller do
  let(:rv) { Fabricate(Group::Regionalverband.name.to_sym, parent: groups(:root)) }
  let(:og) { Fabricate(Group::Ortsgruppe.name.to_sym, parent: rv) }
  let(:vorstand) { Group::OrtsgruppeVorstand.find_by(parent_id: og.id) }
  let(:leiterrunde) { Group::OrtsgruppeLeiterrunde.find_by(parent_id: og.id) }
  let(:vorsitz) { Fabricate(Group::OrtsgruppeVorstand::Vorsitz.name.to_sym, group: vorstand).person }
  let(:report_path) { group_board_member_check_path(vorstand) }

  render_views

  # Layout bindet application.css ein, Assets sind in der Wagon-CI nicht gebaut.
  before { allow(controller).to receive(:_layout).and_return(nil) }

  before { sign_in(vorsitz) }

  it 'zeigt den Button bei Person ohne Mitgliedsrolle' do
    Fabricate(Group::OrtsgruppeVorstand::Mitglied.name.to_sym, group: vorstand)
    get :index, params: { group_id: vorstand.id }

    expect(response.body).to include(report_path)
  end

  it 'zeigt keinen Button, wenn alle Personen Mitglied sind' do
    Fabricate(Group::Ortsgruppe::Mitglied.name.to_sym, group: og, person: vorsitz)
    get :index, params: { group_id: vorstand.id }

    expect(response.body).not_to include(report_path)
  end

  it 'zeigt keinen Button in der Ortsgruppe selbst' do
    get :index, params: { group_id: og.id }

    expect(response.body).not_to include('board_member_check')
  end

  it 'zeigt keinen Button fuer Vorstands-Mitglieder mit nur layer_full' do
    sign_in(Fabricate(Group::OrtsgruppeVorstand::Mitglied.name.to_sym, group: vorstand).person)
    get :index, params: { group_id: vorstand.id }

    expect(response.body).not_to include(report_path)
  end
end
