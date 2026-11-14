# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require "spec_helper"

# Gemeinsame Mail-Fixture: Authentifizierungs-Header (teils doppelt, gemischte
# Schreibweise) und Header, die erhalten bleiben muessen.
shared_context "mail with auth headers" do
  let(:raw_mail) do
    <<~MAIL.gsub("\n", "\r\n")
      Received: from mx.example.com (mx.example.com [1.2.3.4])
      \tby post.example.com with ESMTP
      \tfor <liste@example.com>; Sat, 14 Nov 2026 10:00:00 +0100
      Return-Path: <sender@example.com>
      From: sender@example.com
      To: liste@example.com
      Subject: Test
      DKIM-Signature: v=1; a=rsa-sha256; d=example.com; s=sel; b=abc
      dkim-signature: v=1; a=rsa-sha256; d=example.org; s=sel2; b=def
      DKIM-SIGNATURE: v=1; a=rsa-sha256; d=example.net; s=sel3; b=ghi
      ARC-Seal: i=1; a=rsa-sha256
      arc-seal: i=2; a=rsa-sha256
      ARC-Message-Signature: i=1; a=rsa-sha256
      Authentication-Results: mx.example.com; dkim=pass
      authentication-results: mx2.example.com; dkim=pass
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
      In-Reply-To: <vorher@example.com>
      References: <vorher@example.com>
      Message-ID: <abc@example.com>

      Hallo
    MAIL
  end

  let(:message) do
    mail = Mail.new(raw_mail)
    mail.header["X-Original-To"] = "liste@example.com"
    mail
  end

  let(:removed_names) do
    %w[dkim-signature arc- authentication-results received-spf x-ms- x-microsoft- x-forefront-
      x-exchange- x-originatororg thread-index thread-topic x-dspam]
  end

  def stripped_fields(mail)
    mail.header.fields.select { |f| f.name.downcase.start_with?(*removed_names) }
  end

  def expect_kept_headers(mail)
    expect(mail.header["X-Original-To"].value).to eq "liste@example.com"
    expect(mail.header["Received"]).to be_present
    expect(mail.header["Return-Path"]).to be_present
    expect(mail.header["X-Custom"].value).to eq "keep"
    expect(mail.header["In-Reply-To"].value).to include "vorher@example.com"
    expect(mail.header["References"].value).to include "vorher@example.com"
    expect(mail.message_id).to eq "abc@example.com"
    expect(mail.subject).to eq "Test"
    expect(mail.body.decoded).to include "Hallo"
  end
end

describe Kljb::MailRelay::StripAuthHeaders do
  include_context "mail with auth headers"

  it "is prepended to MailRelay::Lists" do
    expect(MailRelay::Lists.ancestors).to include(described_class)
  end

  it "removes all variants (duplicates, mixed case) and keeps required headers via MailRelay::Lists" do
    expect(stripped_fields(message)).not_to be_empty

    relay = MailRelay::Lists.new(message)

    expect(stripped_fields(relay.message)).to be_empty
    expect_kept_headers(relay.message)
  end

  it "keeps the core behaviour (X-DSPAM removed via super)" do
    relay = MailRelay::Lists.new(message)

    expect(relay.message.header.fields.map(&:name).grep(/dspam/i)).to be_empty
  end

  it ".strip! removes duplicate and mixed-case fields" do
    described_class.strip!(message)

    expect(stripped_fields(message)).to be_empty
    expect(message.header.fields.map(&:name).grep(/\Adkim-signature\z/i)).to be_empty
    expect_kept_headers(message)
  end
end

describe Kljb::MailRelay::BulkMailStripAuthHeaders do
  include_context "mail with auth headers"

  let(:mailing_list) { double("MailingList", mail_address: "liste@example.com") }
  let(:bulk_mail_message) do
    double("Message", raw_source: raw_mail, uid: "abc123", mailing_list: mailing_list)
  end

  it "is prepended to Messages::BulkMail::MailFactory" do
    expect(Messages::BulkMail::MailFactory.ancestors).to include(described_class)
  end

  it "removes authentication headers in the new mail stack and keeps the rest" do
    mail = Messages::BulkMail::MailFactory.new(bulk_mail_message).instance_variable_get(:@mail)

    expect(stripped_fields(mail)).to be_empty # inkl. X-DSPAM
    expect(mail.header["X-Hitobito-Message-UID"].value).to eq "abc123"
    expect(mail.header["Received"]).to be_present
    expect(mail.header["X-Custom"].value).to eq "keep"
    expect(mail.header["References"].value).to include "vorher@example.com"
    expect(mail.message_id).to eq "abc@example.com"
  end
end
