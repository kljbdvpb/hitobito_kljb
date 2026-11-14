# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require 'spec_helper'

# Review M1: OIDC-Claims (Scopes name und with_roles) ohne Spitzname.
describe Kljb::HideNickname::OidcClaims do
  let(:claims) { Doorkeeper::OpenidConnect.configuration.claims }

  def claim_names
    claims.to_h.values.map { |c| c.name.to_s }
  end

  it 'ist auf OidcClaimSetup geprepended' do
    expect(OidcClaimSetup.ancestors.first).to eq described_class
  end

  it 'liefert nach dem Setup keinen nickname-Claim' do
    OidcClaimSetup.new.run
    expect(claim_names).not_to include('nickname')
    expect(claim_names).to include('first_name', 'last_name', 'email')
  end

  it 'laesst andere Claims unveraendert zu' do
    expect { OidcClaimSetup.new.run }.not_to(change { claim_names.sort })
  end
end
