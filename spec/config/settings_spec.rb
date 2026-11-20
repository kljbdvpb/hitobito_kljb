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

  context 'Personen-Cleanup-Schalter (ENV KLJB_PEOPLE_CLEANUP)' do
    # Settings werden beim Boot geladen: die ERB-Auswertung wird daher am YAML direkt geprueft.
    def rendered_settings(env_value)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('KLJB_PEOPLE_CLEANUP').and_return(env_value)
      path = HitobitoKljb::Wagon.root.join('config', 'settings.yml')
      YAML.safe_load(ERB.new(File.read(path)).result, aliases: true)
    end

    it 'ist ohne ENV aus' do
      expect(rendered_settings(nil).dig('people', 'cleanup_job', 'enabled')).to be false
    end

    it 'ist bei anderen Werten als 1 aus' do
      expect(rendered_settings('0').dig('people', 'cleanup_job', 'enabled')).to be false
      expect(rendered_settings('true').dig('people', 'cleanup_job', 'enabled')).to be false
    end

    it 'ist bei KLJB_PEOPLE_CLEANUP=1 an' do
      expect(rendered_settings('1').dig('people', 'cleanup_job', 'enabled')).to be true
    end

    it 'setzt Fristen 3/3/0 Monate (Rollen, Login, Teilnahmen)' do
      cutoff = rendered_settings(nil).dig('people', 'cleanup_cutoff_duration')
      expect(cutoff).to eq('regarding_roles' => 3, 'regarding_current_sign_in_at' => 3,
                         'regarding_event_participations' => 0)
    end

    it 'laedt im Test ohne ENV mit ausgeschaltetem Job' do
      skip 'KLJB_PEOPLE_CLEANUP ist in dieser Umgebung gesetzt' if ENV['KLJB_PEOPLE_CLEANUP'].present?

      expect(Settings.people.cleanup_job.enabled).to be false
      expect(FeatureGate.enabled?('people.cleanup_job')).to be false
    end
  end
end
