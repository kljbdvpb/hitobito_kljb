# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require "spec_helper"

describe Kljb::MailRelay::StripAuthHeaders do
  let(:message) do
    Mail.new(<<~MAIL.gsub("\n", "\r\n"))
      From: sender@example.com
      To: liste@example.com
      Subject: Test
      DKIM-Signature: v=1; a=rsa-sha256; d=example.com; s=sel; b=abc
      ARC-Seal: i=1; a=rsa-sha256
      ARC-Message-Signature: i=1; a=rsa-sha256
      Authentication-Results: mx.example.com; dkim=pass
      Received-SPF: pass
      X-MS-Exchange-Organization-AuthSource: foo
      X-Microsoft-Antispam: BCL:0
      X-Forefront-Antispam-Report: CIP:1.2.3.4
      X-Exchange-Antispam-Report-Test: UriScan
      X-Originatororg: example.com
      Thread-Index: abc
      Thread-Topic: Test
      X-DSPAM-Result: Innocent
      X-Custom: keep
      Message-ID: <abc@example.com>

      Hallo
    MAIL
  end

  let(:removed) do
    %w[DKIM-Signature ARC-Seal ARC-Message-Signature Authentication-Results Received-SPF
      X-MS-Exchange-Organization-AuthSource X-Microsoft-Antispam X-Forefront-Antispam-Report
      X-Exchange-Antispam-Report-Test X-Originatororg Thread-Index Thread-Topic X-DSPAM-Result]
  end

  it "is prepended to MailRelay::Lists" do
    expect(MailRelay::Lists.ancestors.first).to eq described_class
  end

  it "removes authentication and transport headers when building the relay" do
    relay = MailRelay::Lists.new(message)

    removed.each do |name|
      expect(relay.message.header[name]).to be_nil, "#{name} wurde nicht entfernt"
    end
  end

  it "keeps all other headers and the body" do
    relay = MailRelay::Lists.new(message)

    expect(relay.message.header["X-Custom"].value).to eq "keep"
    expect(relay.message.subject).to eq "Test"
    expect(relay.message.message_id).to eq "abc@example.com"
    expect(relay.message.body.decoded).to include "Hallo"
  end
end
