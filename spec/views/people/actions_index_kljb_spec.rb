# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require 'spec_helper'

# Partial wird direkt gerendert (Erweiterung von people/_actions_index via render_extensions
# :actions_index, Core 2.11.5 people/_actions_index.html.haml:11); Ability ist die echte.
describe 'people/_actions_index_kljb.html.haml' do
  let(:rv) { Fabricate(Group::Regionalverband.name.to_sym, parent: groups(:root)) }
  let(:og) { Fabricate(Group::Ortsgruppe.name.to_sym, parent: rv) }
  let(:vorstand) { Group::OrtsgruppeVorstand.find_by(parent_id: og.id) }
  let(:vorsitz) { Fabricate(Group::OrtsgruppeVorstand::Vorsitz.name.to_sym, group: vorstand).person }
  let(:current_user) { vorsitz }
  let(:group) { vorstand }
  let(:report_path) { group_board_member_check_path(vorstand) }

  before do
    allow(controller).to receive(:current_user) { current_user }
    allow(view).to receive(:current_user) { current_user }
    assign(:group, group.decorate)
  end

  subject do
    render partial: 'people/actions_index_kljb'
    Capybara::Node::Simple.new(rendered)
  end

  it 'zeigt den Button bei Person ohne Mitgliedsrolle' do
    Fabricate(Group::OrtsgruppeVorstand::Mitglied.name.to_sym, group: vorstand)

    is_expected.to have_link('Ohne Mitgliedschaft (2)', href: report_path)
  end

  it 'zeigt keinen Button, wenn alle Personen Mitglied sind' do
    Fabricate(Group::Ortsgruppe::Mitglied.name.to_sym, group: og, person: vorsitz)

    is_expected.not_to have_link(href: report_path)
  end

  context 'in der Ortsgruppe selbst' do
    let(:group) { og }

    it 'zeigt keinen Button' do
      is_expected.not_to have_link(href: report_path)
    end
  end

  context 'als Vorstands-Mitglied mit nur layer_full' do
    let(:current_user) { Fabricate(Group::OrtsgruppeVorstand::Mitglied.name.to_sym, group: vorstand).person }

    it 'zeigt keinen Button' do
      is_expected.not_to have_link(href: report_path)
    end
  end

  context 'als Vorsitz einer anderen Ortsgruppe' do
    let(:current_user) do
      og2 = Fabricate(Group::Ortsgruppe.name.to_sym, parent: rv)
      Fabricate(Group::OrtsgruppeVorstand::Vorsitz.name.to_sym,
                group: Group::OrtsgruppeVorstand.find_by(parent_id: og2.id)).person
    end

    it 'zeigt keinen Button (Layer-Grenze)' do
      Fabricate(Group::OrtsgruppeVorstand::Mitglied.name.to_sym, group: vorstand)

      is_expected.not_to have_link(href: report_path)
    end
  end

  context 'im Regionalverband-Vorstand' do
    let(:group) { Group::RegionalverbandVorstand.find_by(parent_id: rv.id) }
    let(:current_user) { Fabricate(Group::RegionalverbandVorstand::Vorsitz.name.to_sym, group: group).person }

    it 'zeigt den Button, solange keine Mitgliedsrolle in einer Ortsgruppe des RV besteht' do
      is_expected.to have_link('Ohne Mitgliedschaft (1)', href: group_board_member_check_path(group))
    end

    it 'zeigt keinen Button, wenn Mitglied in einer Ortsgruppe des RV' do
      Fabricate(Group::Ortsgruppe::Mitglied.name.to_sym, group: og, person: current_user)

      is_expected.not_to have_link(href: group_board_member_check_path(group))
    end
  end
end
