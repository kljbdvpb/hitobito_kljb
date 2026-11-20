# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require 'spec_helper'

describe Kljb::People::CleanupFinder do
  let(:rv) { Fabricate(Group::Regionalverband.name.to_sym, parent: groups(:root)) }
  let(:og) { Fabricate(Group::Ortsgruppe.name.to_sym, parent: rv) }

  subject(:found) { ::People::CleanupFinder.new.run }

  # Person, die bereits laenger als die Rollen-Frist existiert
  def old_person(created_at: 1.year.ago)
    Fabricate(:person).tap { |p| p.update_columns(created_at: created_at, current_sign_in_at: nil) }
  end

  def role_for(person, start_on:, end_on:)
    role = Fabricate(Group::Ortsgruppe::Mitglied.name.to_sym, group: og, person: person)
    role.update_columns(start_on: start_on, end_on: end_on)
    role
  end

  it 'ist als Override in den Core-Finder eingehaengt' do
    expect(::People::CleanupFinder.ancestors).to include(described_class)
  end

  it 'wirft keinen Fehler, wenn die Root-Person fehlt' do
    allow(::Person).to receive(:root).and_return(nil)
    person = old_person
    expect { found.to_a }.not_to raise_error
    expect(found).to include(person)
  end

  it 'schliesst die Root-Person weiterhin aus, wenn sie existiert' do
    root = old_person
    allow(::Person).to receive(:root).and_return(root)
    expect(found).not_to include(root)
  end

  it 'findet Person, deren Rolle vor 4 Monaten endete (ohne Login)' do
    person = old_person
    role_for(person, start_on: 2.years.ago.to_date, end_on: 4.months.ago.to_date)
    expect(found).to include(person)
  end

  it 'findet Person nicht, deren Rolle vor 2 Monaten endete' do
    person = old_person
    role_for(person, start_on: 2.years.ago.to_date, end_on: 2.months.ago.to_date)
    expect(found).not_to include(person)
  end

  it 'findet Person nicht mit alter beendeter und kuenftiger Rolle' do
    person = old_person
    role_for(person, start_on: 2.years.ago.to_date, end_on: 1.year.ago.to_date)
    role_for(person, start_on: 1.month.from_now.to_date, end_on: nil)
    expect(found).not_to include(person)
  end

  it 'findet Person nicht mit aktiver Rolle' do
    person = old_person
    role_for(person, start_on: 1.year.ago.to_date, end_on: nil)
    expect(found).not_to include(person)
  end

  it 'findet Person ohne Rolle nicht, wenn sie vor 1 Monat angelegt wurde' do
    person = old_person(created_at: 1.month.ago)
    expect(found).not_to include(person)
  end

  it 'findet Person ohne Rolle, wenn sie vor 4 Monaten angelegt wurde' do
    person = old_person(created_at: 4.months.ago)
    expect(found).to include(person)
  end

  it 'findet Person nicht, die sich vor 1 Monat angemeldet hat' do
    person = old_person
    person.update_columns(current_sign_in_at: 1.month.ago)
    expect(found).not_to include(person)
  end

  context 'Settings' do
    it 'aktiviert den Cleanup-Job mit 3 Monaten Fristen und 120 Monaten Teilnahmen' do
      expect(Settings.people.cleanup_job.enabled).to be true
      expect(FeatureGate.enabled?('people.cleanup_job')).to be true
      durations = Settings.people.cleanup_cutoff_duration
      expect(durations.regarding_roles).to eq 3
      expect(durations.regarding_current_sign_in_at).to eq 3
      expect(durations.regarding_event_participations).to eq 120
    end
  end
end
