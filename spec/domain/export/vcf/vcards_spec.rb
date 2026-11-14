# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require 'spec_helper'

describe Export::Vcf::Vcards do
  let(:person) { people(:member) }

  before { person.update_columns(nickname: 'Spitzi') }

  it 'schreibt keinen Spitznamen (NICKNAME) in die vCard' do
    vcf = described_class.new.generate(Person.only_public_data.where(id: person.id))
    expect(vcf).to include('FN:My Member').or include('N:Member;My')
    expect(vcf).not_to include('NICKNAME')
    expect(vcf).not_to include('Spitzi')
  end
end
