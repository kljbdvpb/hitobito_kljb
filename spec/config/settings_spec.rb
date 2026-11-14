# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require 'spec_helper'

# Wagon-Settings ueberschreiben die Core-Settings (Settings.add_source! in wagon.rb).
describe 'Wagon-Settings' do
  it 'Absendername ist "KLJB Mitgliederdatenbank" (nicht "KLIB")' do
    expect(Settings.email.sender).to start_with('KLJB Mitgliederdatenbank <noreply@')
    expect(Settings.email.sender).not_to include('KLIB')
  end

  # Core 2.11.5 liest Settings.impersonate.notify in
  # Person::ImpersonationController#start_impersonation (Mail an die Zielperson).
  it 'Impersonation loest keine Benachrichtigung aus' do
    expect(Settings.impersonate.notify).to eq(false)
  end
end
