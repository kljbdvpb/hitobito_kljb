# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require 'spec_helper'
require 'csv'

# Spitzname ist ausgeblendet, :nickname bleibt aber in Person::PUBLIC_ATTRS,
# sonst bricht Person.only_public_data (MissingAttributeError).
describe 'Spitzname ausblenden' do
  let(:person) { people(:member) }

  before { person.update_columns(nickname: 'Spitzi') }

  it 'bleibt in PUBLIC_ATTRS, ist aber nicht in used_attributes/FILTER_ATTRS' do
    expect(Person::PUBLIC_ATTRS).to include(:nickname)
    expect(Person.used_attributes).not_to include(:nickname)
    expect(Person::FILTER_ATTRS).not_to include(:nickname)
    expect(Person::MERGABLE_ATTRS).not_to include(:nickname)
  end

  it 'person_name enthaelt keinen Spitznamen' do
    expect(Person.only_public_data.find(person.id).person_name).not_to include('Spitzi')
  end

  {
    Export::Tabular::People::PeopleAddress => -> (id) { Person.only_public_data.where(id: id) },
    # wie Core-Export (people_export_job.rb full_entries): select("people.*")
    Export::Tabular::People::PeopleFull => -> (id) { Person.where(id: id).select("people.*") }
  }.each do |klass, scope|
    it "#{klass.name.demodulize}-CSV wirft nicht und enthaelt keinen Spitznamen" do
      list = scope.call(person.id)
      data = nil
      expect { data = klass.csv(list) }.not_to raise_error
      csv = CSV.parse(data.sub(Export::Csv::UTF8_BOM, ''), headers: true,
                                                          col_sep: Settings.csv.separator)
      expect(csv.headers).not_to include(Person.human_attribute_name(:nickname))
      expect(data).not_to include('Spitzi')
    end
  end

  it 'vCard-Export mit only_public_data wirft nicht' do
    scope = Person.only_public_data.where(id: person.id)
    expect { Export::Vcf::Vcards.new.generate(scope) }.not_to raise_error
  end
end
