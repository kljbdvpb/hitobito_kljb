# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require 'spec_helper'

describe Kljb::PersonProfileContact do
  let(:person) do
    people(:member).tap do |p|
      p.update_columns(street: 'Hauptstrasse', housenumber: '12', zip_code: '33098',
                       town: 'Paderborn')
    end
  end
  let(:decorated) { person.decorate }
  subject(:contact) { described_class.new(decorated) }

  it 'liefert keine Postanschrift' do
    expect(decorated.complete_address).to include('Paderborn') # Gegenprobe: Decorator selbst
    expect(contact.complete_address).to be_blank
    expect(contact.all_additional_addresses(true)).to be_blank
  end

  it 'reicht Name und E-Mail unveraendert durch' do
    expect(contact.contact_name.to_s).to include('My Member')
    expect(contact.primary_email.to_s).to include(person.email)
  end

  it 'ist im Personenprofil-Partial verdrahtet, ohne Kartenlink' do
    partial = File.read(HitobitoKljb::Wagon.root.join('app/views/people/_contact_data.html.haml'))
    expect(partial).to include('Kljb::PersonProfileContact.new(person)')
    expect(partial).not_to match(/^\s*=\s*link_to_address/)
    expect(partial).not_to include('contact-marker.')
  end
end
