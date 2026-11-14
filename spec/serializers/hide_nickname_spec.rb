# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require 'spec_helper'

# Legacy-REST (/groups/:id/people.json u. a.): Schluessel nickname entfaellt.
describe 'Spitzname in Legacy-REST-Serialisierern' do
  let(:person) { people(:member).tap { |p| p.update_columns(nickname: 'Spitzi') }.decorate }
  let(:controller) { double.as_null_object }

  it 'PersonSerializer enthaelt keinen nickname' do
    hash = PersonSerializer.new(person, controller: controller).to_hash
    expect(hash[:people].first).not_to have_key(:nickname)
    expect(hash[:people].first).to have_key(:first_name)
    expect(hash.to_s).not_to include('Spitzi')
  end

  it 'PeopleSerializer enthaelt keinen nickname' do
    hash = PeopleSerializer.new(person, group: groups(:root), multiple_groups: true,
                                        controller: controller).to_hash
    expect(hash[:people].first).not_to have_key(:nickname)
    expect(hash[:people].first).to have_key(:last_name)
  end

  it 'UserSerializer enthaelt keinen nickname' do
    hash = UserSerializer.new(person, controller: controller).to_hash
    expect(hash[:people].first).not_to have_key(:nickname)
  end
end
