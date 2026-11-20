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

  context 'Regressionsschutz der Core-Filter (bleiben nach dem base_scope-Override wirksam)' do
    let(:future_event) do
      Fabricate(:event, dates: [Event::Date.new(start_at: 10.days.from_now)])
    end
    let(:past_event) do
      Fabricate(:event, dates: [Event::Date.new(start_at: 10.days.ago, finish_at: 5.days.ago)])
    end

    it 'findet Person mit Teilnahme an vergangenem Event (Job loescht sie, Teilnahmefrist 0)' do
      person = old_person
      Event::Participation.create!(event: past_event, participant: person)
      expect(found).to include(person)
    end

    it 'findet Person nicht mit Teilnahme an kuenftigem Event' do
      person = old_person
      Event::Participation.create!(event: future_event, participant: person)
      expect(found).not_to include(person)
    end

    it 'findet People Manager nicht (verwaltet eine andere Person)' do
      manager = old_person
      manager.manageds = [old_person]
      expect(found).not_to include(manager)
    end

    it 'findet bereits minimierte Person nicht' do
      person = old_person
      person.update_columns(minimized_at: 1.day.ago)
      expect(found).not_to include(person)
    end
  end

  context 'Direkt-Abonnenten von Verteilern' do
    let(:list) { Fabricate(:mailing_list, group: og) }

    it 'schuetzt Person mit direkter Subscription' do
      person = old_person
      Subscription.create!(mailing_list: list, subscriber: person)
      expect(found).not_to include(person)
    end

    it 'schuetzt Person nicht, deren Subscription ausgeschlossen (excluded) ist' do
      person = old_person
      Subscription.create!(mailing_list: list, subscriber: person, excluded: true)
      expect(found).to include(person)
    end

    it 'schuetzt nicht, wenn protect_direct_subscribers? false liefert' do
      allow(Kljb::People::CleanupFinder).to receive(:protect_direct_subscribers?).and_return(false)
      person = old_person
      Subscription.create!(mailing_list: list, subscriber: person)
      expect(found).to include(person)
    end

    it 'schuetzt Direkt-Abonnenten standardmaessig (Fachfrage F4 offen)' do
      expect(Kljb::People::CleanupFinder.protect_direct_subscribers?).to be true
    end
  end

  context 'Settings' do
    it 'setzt die Fristen auf 3 Monate (Rollen, Login) und 0 (Teilnahmen: loeschen statt minimieren)' do
      durations = Settings.people.cleanup_cutoff_duration
      expect(durations.regarding_roles).to eq 3
      expect(durations.regarding_current_sign_in_at).to eq 3
      expect(durations.regarding_event_participations).to eq 0
    end
  end
end
