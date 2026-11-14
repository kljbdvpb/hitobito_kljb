# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require 'spec_helper'

# JSON:API: nickname wird nie ausgeliefert (Wert nil, Schema unveraendert).
describe PersonResource, type: :resource do
  let(:user) { people(:admin) }
  let(:context) do
    double(current_ability: Ability.new(user), url_options: { host: 'example.com' },
           current_scopes: %w[api]).tap { |c| c.extend(Rails.application.routes.url_helpers) }
  end

  around do |example|
    RSpec::Mocks.with_temporary_scope do
      Graphiti.with_context(context) { example.run }
    end
  end

  it 'liefert keinen Spitznamen' do
    person = people(:member)
    person.update_columns(nickname: 'Spitzi')

    json = PersonResource.all(filter: { id: person.id.to_s }).to_jsonapi
    attributes = JSON.parse(json)['data'].first['attributes']

    expect(attributes['first_name']).to eq 'My'
    expect(attributes['nickname']).to be_nil
    expect(json).not_to include('Spitzi')
  end
end

# Review M2: nickname weder filter-, sortier- noch schreibbar (kein Such-Orakel).
describe PersonResource, 'nickname restrictions' do
  it 'ist nicht schreibbar' do
    expect(PersonResource.config[:attributes][:nickname][:writable]).to be false
  end

  it 'hat weder Filter noch Sortierung' do
    expect(PersonResource.config[:filters]).not_to have_key(:nickname)
    expect(PersonResource.config[:sorts]).not_to have_key(:nickname)
  end
end
