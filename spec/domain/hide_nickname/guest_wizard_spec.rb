# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require 'spec_helper'

# Review N2: nickname zaehlt auch im Gast-Wizard nicht als Pflichtfeld.
describe Wizards::RegisterNewEventGuestWizard do
  let(:event) { events(:top_event) }
  let(:wizard) do
    described_class.allocate.tap { |w| w.instance_variable_set(:@event, event) }
  end

  it 'ist mit Kljb::HideNickname::RequiredAttrs geprepended' do
    expect(described_class.ancestors.first).to eq Kljb::HideNickname::RequiredAttrs
  end

  it 'entfernt nickname aus required_attrs, behaelt die uebrigen' do
    event.required_contact_attrs = %w[nickname email]
    expect(wizard.required_attrs).not_to include(:nickname)
    expect(wizard.required_attrs).to include(:email)
  end
end
