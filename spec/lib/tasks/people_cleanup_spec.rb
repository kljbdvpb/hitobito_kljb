# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require 'spec_helper'
require 'rake'

describe 'hitobito_kljb:people_cleanup:dry_run' do
  let(:task_name) { 'hitobito_kljb:people_cleanup:dry_run' }
  let(:task) { Rake::Task[task_name] }

  before do
    Rails.application.load_tasks unless Rake::Task.task_defined?(task_name)
    task.reenable
  end

  def old_person
    Fabricate(:person).tap { |p| p.update_columns(created_at: 1.year.ago, current_sign_in_at: nil) }
  end

  def capture_task(env = {})
    env.each { |k, v| ENV[k] = v }
    io = StringIO.new
    $stdout = io
    task.invoke
    io.string
  ensure
    $stdout = STDOUT
    env.each_key { |k| ENV.delete(k) }
  end

  # Wagon-Frist ist 0 (alles wird geloescht); fuer den Minimierungs-Zaehler explizit 120 Monate
  before do
    allow(Settings.people.cleanup_cutoff_duration)
      .to receive(:regarding_event_participations).and_return(120)
  end

  let!(:to_delete) { old_person }
  let!(:to_minimize) do
    old_person.tap do |person|
      event = Fabricate(:event, dates: [Event::Date.new(start_at: 1.year.ago, finish_at: 1.year.ago)])
      Event::Participation.create!(event: event, participant: person)
    end
  end
  let!(:signed_in_before) do
    old_person.tap { |p| p.update_columns(current_sign_in_at: 6.months.ago, sign_in_count: 3) }
  end

  it 'gibt Zaehler getrennt nach geloescht/minimiert aus und schreibt nichts' do
    expect do
      output = capture_task
      expect(output).to include('TROCKENLAUF')
      expect(output).to match(/WUERDE_GELOESCHT=\d+/)
      expect(output).to match(/WUERDE_MINIMIERT=1$/)
      expect(output).to match(/je_angemeldet=1 /)
    end.not_to(change { [::Person.count, ::Person.where.not(minimized_at: nil).count] })
  end

  it 'minimiert mit den Wagon-Settings (Frist 0) nichts, sondern loescht alle Kandidaten' do
    allow(Settings.people.cleanup_cutoff_duration)
      .to receive(:regarding_event_participations).and_return(0)

    output = capture_task

    expect(output).to match(/WUERDE_MINIMIERT=0$/)
  end

  it 'laeuft unabhaengig vom Schalter (Job aus)' do
    allow(Settings.people.cleanup_job).to receive(:enabled).and_return(false)
    expect(capture_task).to include('JOB_AKTIV=false')
  end

  it 'gibt weder Namen noch E-Mail-Adressen aus' do
    output = capture_task
    expect(output).not_to include(to_delete.email)
    expect(output).not_to match(/IDS_/)
  end

  it 'gibt mit IDS=1 die Personen-IDs aus' do
    output = capture_task('IDS' => '1')
    expect(output).to match(/IDS_GELOESCHT=.*\b#{to_delete.id}\b/)
    expect(output).to match(/IDS_MINIMIERT=#{to_minimize.id}$/)
  end
end
