# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require 'spec_helper'
require 'rake'

describe 'hitobito_kljb:orphan_groups:cleanup' do
  let(:task_name) { 'hitobito_kljb:orphan_groups:cleanup' }
  let(:task) { Rake::Task[task_name] }
  let(:rv) { Fabricate(Group::Regionalverband.name.to_sym, parent: groups(:root)) }
  let!(:orphan_og) { Fabricate(Group::Ortsgruppe.name.to_sym, parent: rv) }

  before do
    Rails.application.load_tasks unless Rake::Task.task_defined?(task_name)
    task.reenable
    orphan_og.update_columns(parent_id: Group.unscoped.maximum(:id) + 1000)
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

  it 'schreibt im Trockenlauf nichts und zeigt abhaengige Objekte' do
    output = nil
    expect { output = capture_task }.not_to(change do
      [::Group.unscoped.where.not(deleted_at: nil).count, ::Role.with_inactive.count]
    end)
    expect(output).to include('TROCKENLAUF', "GROUP id=#{orphan_og.id}", 'invoice_configs=1')
  end

  it 'bricht bei APPLY=1 mit abhaengigen Objekten ab, ohne zu schreiben' do
    expect do
      expect { capture_task('APPLY' => '1') }.to raise_error(SystemExit)
    end.not_to(change { ::Group.unscoped.where.not(deleted_at: nil).count })
  end

  it 'fuehrt APPLY=1 mit FORCE=1 aus' do
    output = capture_task('APPLY' => '1', 'FORCE' => '1')

    expect(output).to include('ERGEBNIS gruppen_geloescht=4')
    expect(::Group.unscoped.find(orphan_og.id).deleted_at).to be_present
  end
end
