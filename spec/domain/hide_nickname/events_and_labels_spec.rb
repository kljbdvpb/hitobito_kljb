# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require 'spec_helper'

# Event-Kontaktattribute und Etiketten: Spitzname spielt keine Rolle mehr.
describe 'Spitzname in Events und Etiketten' do
  let(:event) { events(:top_event) }

  it 'ist kein moegliches Event-Kontaktattribut' do
    expect(Event.possible_contact_attrs).not_to include(:nickname)
  end

  it 'Event mit altem nickname in required/hidden_contact_attrs bleibt gueltig' do
    # Ohne Bereinigung lehnt Core das als contact_attr_invalid ab.
    event.required_contact_attrs = %w[nickname email]
    event.hidden_contact_attrs = %w[nickname]

    expect(event).to be_valid
    expect(event.required_contact_attrs.map(&:to_s)).not_to include('nickname')
    expect(event.hidden_contact_attrs.map(&:to_s)).not_to include('nickname')
  end

  it 'nickname zaehlt nicht als Pflichtfeld bei Teilnahme-Kontaktdaten' do
    event.required_contact_attrs = %w[nickname]
    data = Event::ParticipationContactData.new(event, people(:member), {})
    expect(data.required_attrs).not_to include(:nickname)
  end

  it 'Briefetiketten drucken keinen Spitznamen' do
    person = people(:member)
    person.update_columns(nickname: 'Spitzi')
    label = Contactable::Address.new(person).for_pdf_label('My Member', true)
    expect(label).not_to include('Spitzi')
  end
end
