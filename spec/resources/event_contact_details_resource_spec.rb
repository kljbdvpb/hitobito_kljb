# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require 'spec_helper'

# Review N2: Event::ContactDetailsResource liefert keinen Spitznamen der Kontaktperson.
describe Event::ContactDetailsResource, type: :resource do
  let(:user) { people(:admin) }
  let(:event) { events(:top_event) }
  let(:context) do
    double(current_ability: Ability.new(user), url_options: { host: 'example.com' },
           current_scopes: %w[api events]).tap { |c| c.extend(Rails.application.routes.url_helpers) }
  end

  around do |example|
    RSpec::Mocks.with_temporary_scope do
      Graphiti.with_context(context) { example.run }
    end
  end

  it 'nickname ist weder schreib-, filter- noch sortierbar' do
    attribute = described_class.config[:attributes][:nickname]
    expect(attribute[:writable]).to be false
    expect(attribute[:filterable]).to be false
    expect(attribute[:sortable]).to be false
  end

  it 'liefert den Spitznamen der Kontaktperson nicht aus' do
    contact = people(:member)
    contact.update_columns(nickname: 'Spitzi')
    event.update_columns(contact_id: contact.id)

    json = described_class.all(filter: { id: event.id.to_s }).to_jsonapi
    attributes = JSON.parse(json)['data'].first['attributes']

    expect(attributes['nickname']).to be_nil
    expect(json).not_to include('Spitzi')
  end
end
