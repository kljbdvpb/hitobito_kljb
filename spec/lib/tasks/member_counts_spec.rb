# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require 'spec_helper'
require 'rake'

describe 'hitobito_kljb:member_counts:backfill_age_groups' do
  let(:group) { groups(:paderborn) }
  let(:task) { Rake::Task['hitobito_kljb:member_counts:backfill_age_groups'] }

  before do
    Rails.application.load_tasks unless Rake::Task.task_defined?(task_name)
    task.reenable
    person = Fabricate(:person, birthday: '2000-01-01')
    role = Fabricate('Group::Ortsgruppe::Mitglied', group: group, person: person)
    role.update_columns(start_on: '2021-01-01')
    group.update_columns(members_normal: 42, members_discounted: 7)
  end

  def task_name
    'hitobito_kljb:member_counts:backfill_age_groups'
  end

  def run_task(env = {})
    env.each { |k, v| ENV[k] = v }
    travel_to('2021-12-14') { expect { task.invoke }.to output(/BACKFILL/).to_stdout }
  ensure
    env.each_key { |k| ENV.delete(k) }
  end

  it 'writes nothing without APPLY=1' do
    run_task
    group.reload
    expect(group.members_from_14).to be_nil
    expect(group.members_normal).to eq 42
  end

  it 'writes only the age columns with APPLY=1' do
    run_task('APPLY' => '1')
    group.reload
    expect(group.members_from_14).to eq 1
    expect(group.members_up_to_27).to eq 1
    expect(group.members_normal).to eq 42
    expect(group.members_discounted).to eq 7
  end
end
