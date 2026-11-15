# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require 'spec_helper'

describe FullTextController, type: :controller do
  let(:separator) { { 'label' => '—' * 20 } }
  let(:group_ids) { [groups(:paderborn).id, groups(:bonn).id] }
  let(:person_ids) { [people(:leader).id, people(:member).id] }

  before do
    sign_in(people(:admin))
    stub_search(SearchStrategies::PersonSearch, Person.where(id: person_ids))
    stub_search(SearchStrategies::GroupSearch, Group.where(id: group_ids))
    stub_search(SearchStrategies::EventSearch, Event.none)
  end

  def stub_search(klass, scope)
    instance = instance_double(klass, search: scope)
    allow(klass).to receive(:new).and_return(instance)
  end

  def json_results
    JSON.parse(response.body)
  end

  context 'quicksearch (json)' do
    before { get :index, params: { q: 'Paderborn' }, format: :json }

    it 'liefert Gruppen vor Personen' do
      expect(json_results.first['type']).to eq('group')
      expect(json_results.map { |r| r['type'] }.compact).to eq(%w[group group person person])
    end

    it 'setzt genau einen Trenner zwischen Gruppen und Personen, keinen am Rand' do
      results = json_results
      expect(results.count(separator)).to eq(1)
      expect(results.index(separator)).to eq(2)
      expect(results.first).not_to eq(separator)
      expect(results.last).not_to eq(separator)
    end

    it 'enthaelt weiterhin alle Personen' do
      ids = json_results.select { |r| r['type'] == 'person' }.map { |r| r['id'] }
      expect(ids).to match_array(person_ids)
    end
  end

  context 'ohne Gruppentreffer' do
    before do
      stub_search(SearchStrategies::GroupSearch, Group.none)
      get :index, params: { q: 'Leader' }, format: :json
    end

    it 'liefert nur Personen ohne Trenner' do
      expect(json_results.map { |r| r['type'] }).to eq(%w[person person])
      expect(json_results).not_to include(separator)
    end
  end

  context 'ohne Personentreffer' do
    before do
      stub_search(SearchStrategies::PersonSearch, Person.none)
      get :index, params: { q: 'Bonn' }, format: :json
    end

    it 'liefert nur Gruppen ohne Trenner' do
      expect(json_results.map { |r| r['type'] }).to eq(%w[group group])
    end
  end

  it 'begrenzt Gruppen auf MAX_GROUPS, Personen bleiben sichtbar' do
    stub_const('Kljb::QuicksearchGroupsFirst::MAX_GROUPS', 1)
    get :index, params: { q: 'Paderborn' }, format: :json
    types = json_results.map { |r| r['type'] }
    expect(types).to eq(['group', nil, 'person', 'person'])
  end

  it 'laesst die HTML-Ergebnisseite unveraendert' do
    get :index, params: { q: 'Paderborn' }
    expect(assigns(:groups).map(&:id)).to match_array(group_ids)
    expect(assigns(:people).map(&:id)).to match_array(person_ids)
  end
end
