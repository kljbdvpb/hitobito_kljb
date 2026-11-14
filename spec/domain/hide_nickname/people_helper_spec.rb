# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require 'spec_helper'

# Review N2: Listenkoepfe "Nachname | Vorname | Spitzname" ohne Spitzname-Spalte.
describe PeopleHelper, type: :helper do
  let(:table) do
    double('table').tap do |t|
      allow(t).to receive(:sort_header) { |attr, _label| "sort:#{attr}" }
      allow(t).to receive(:col) { |content, &_block| content }
    end
  end

  it 'ist auf PeopleHelper geprepended' do
    expect(PeopleHelper.ancestors.first).to eq Kljb::HideNickname::PeopleHelper
  end

  it 'blendet nickname (sortierbar oder nicht) aus dem Listenkopf aus' do
    header = helper.sortable_grouped_person_attr(table, last_name: true, first_name: true,
                                                        nickname: true) {}
    expect(header).to include('sort:last_name', 'sort:first_name')
    expect(header).not_to include('nickname')
    expect(header).not_to include(Person.human_attribute_name(:nickname))
  end

  it 'laesst den Kopf ohne nickname unveraendert' do
    header = helper.sortable_grouped_person_attr(table, last_name: true, first_name: false) {}
    expect(header).to include('sort:last_name')
    expect(header).to include(Person.human_attribute_name(:first_name))
  end
end
