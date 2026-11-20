# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require 'spec_helper'

# Ende-zu-Ende: Core-Job People::CleanupJob mit dem Wagon-Finder (Kljb::People::CleanupFinder).
describe People::CleanupJob do
  let(:rv) { Fabricate(Group::Regionalverband.name.to_sym, parent: groups(:root)) }
  let(:og) { Fabricate(Group::Ortsgruppe.name.to_sym, parent: rv) }

  subject(:job) { described_class.new }

  before { allow(Settings.people.cleanup_job).to receive(:enabled).and_return(true) }

  def old_person(created_at: 1.year.ago)
    Fabricate(:person).tap { |p| p.update_columns(created_at: created_at, current_sign_in_at: nil) }
  end

  def exists?(person)
    ::Person.exists?(person.id)
  end

  it 'loescht Person ohne Rolle (4 Monate alt) und laesst geschuetzte Personen bestehen' do
    candidate = old_person(created_at: 4.months.ago)
    young = old_person(created_at: 1.month.ago)
    with_role = old_person
    Fabricate(Group::Ortsgruppe::Mitglied.name.to_sym, group: og, person: with_role)
    future_role = old_person
    Fabricate(Group::Ortsgruppe::Mitglied.name.to_sym, group: og, person: future_role,
                                                       start_on: Date.current + 1.month)
    subscriber = old_person
    Subscription.create!(mailing_list: Fabricate(:mailing_list, group: og), subscriber: subscriber)
    manager = old_person
    manager.manageds = [young]
    recent_login = old_person.tap { |p| p.update_columns(current_sign_in_at: 1.month.ago) }
    signed_in_long_ago = old_person.tap { |p| p.update_columns(current_sign_in_at: 6.months.ago) }

    expect { job.perform }.to change { ::Person.count }.by(-2)

    expect(exists?(candidate)).to be false
    expect(exists?(signed_in_long_ago)).to be false
    [young, with_role, future_role, subscriber, manager, recent_login].each do |person|
      expect(exists?(person)).to be(true), "Person #{person.id} wurde geloescht"
    end
  end

  it 'minimiert statt zu loeschen bei Teilnahme an einem Event der letzten 120 Monate' do
    person = old_person
    event = Fabricate(:event, dates: [Event::Date.new(start_at: 2.years.ago, finish_at: 2.years.ago)])
    Event::Participation.create!(event: event, participant: person)

    expect { job.perform }.not_to change { ::Person.count }

    expect(person.reload.minimized_at).to be_present
  end

  it 'laesst Person mit Teilnahme an kuenftigem Event unberuehrt' do
    person = old_person
    event = Fabricate(:event, dates: [Event::Date.new(start_at: 10.days.from_now)])
    Event::Participation.create!(event: event, participant: person)

    expect { job.perform }.not_to change { ::Person.count }

    expect(person.reload.minimized_at).to be_nil
  end

  it 'ruehrt bereits minimierte Personen nicht an' do
    person = old_person.tap { |p| p.update_columns(minimized_at: 1.day.ago) }

    expect { job.perform }.not_to change { ::Person.count }

    expect(exists?(person)).to be true
  end

  it 'loescht nichts, wenn der Schalter aus ist (Default ohne KLJB_PEOPLE_CLEANUP)' do
    allow(Settings.people.cleanup_job).to receive(:enabled).and_return(false)
    person = old_person

    expect { job.perform }.not_to change { ::Person.count }

    expect(exists?(person)).to be true
  end
end
