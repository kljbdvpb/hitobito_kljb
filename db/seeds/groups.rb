# frozen_string_literal: true

#  Copyright (c) 2012-2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.


Group::Dioezesanverband.seed_once(
  :parent_id,
  parent_id: nil,

  name: 'KLJB Paderborn',

  address: 'Leostraße 21',
  zip_code: '33098',
  town: 'Paderborn',
  country: 'Deutschland',

  email: 'buero@kljb-paderborn.de'
)
