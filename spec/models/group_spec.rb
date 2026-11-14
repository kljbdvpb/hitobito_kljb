# frozen_string_literal: true

#  Copyright (c) 2012-2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.


require 'spec_helper'

describe Group do
  include_examples 'group types'

  # Fachentscheidung: Arbeitsgruppen (Ag) sind keine moeglichen Kindgruppen mehr.
  describe 'possible_children' do
    [Group::Dioezesanverband, Group::Regionalverband, Group::Ortsgruppe].each do |type|
      it "#{type.name} enthaelt keine Ag-Gruppen" do
        expect(type.possible_children.map(&:name)).not_to include(/Ag\z/)
      end
    end

    it 'Ortsgruppe erlaubt weiterhin ihre Standard-Kindgruppen' do
      expect(Group::Ortsgruppe.possible_children).to match_array(Group::Ortsgruppe.default_children)
    end
  end
end
