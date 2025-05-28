# frozen_string_literal: true

RSpec.describe CfaSecurityControls::Hyperproof::Clients::Hyperproof do
  subject(:client) { described_class.new }

  let(:conn) { Faraday.new { |b| b.adapter :test, stubs } }
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }

  before do
    allow(Faraday).to receive(:new).and_return(conn)
  end

  describe '#create_label' do
    let(:data) { { name: 'Test Label', description: 'Test Description' } }

    before do
      stubs.post('/labels') { [201, {}, data] }
    end

    it 'creates a label with the given name and description' do
      expect(client.create_label(**data)).to eq(data)
    end
  end

  describe '#labels' do
    let(:data) { [{ name: 'Label 1' }, { name: 'Label 2' }] }

    before do
      stubs.get('/labels') { [200, {}, data] }
    end

    it 'retrieves all labels' do
      expect(client.labels).to eq(data)
    end
  end

  describe '#create_proof' do
    let(:data) { { name: 'proof.csv', file: '/path/to/proof.csv' } }
    let(:response) { { id: '309e2191-75d7-4f8b-8750-7c852e7a77ad', name: 'proof.csv' } }
    let(:file) { instance_double(Faraday::UploadIO) }

    before do
      allow(Faraday::UploadIO).to receive(:new).and_return(file)
      allow(Marcel::MimeType).to receive(:for).and_return('text/csv')
    end

    context 'when the proof is not associated with a label' do
      before do
        stubs.post('/proof') { [201, {}, response] }
      end

      it 'creates a proof without a label' do
        expect(client.create_proof(**data)).to eq(response)
      end

      it 'attaches the file to the request with MIME type' do
        client.create_proof(**data)

        expect(Faraday::UploadIO).to have_received(:new).with(
          '/path/to/proof.csv',
          'text/csv',
          'proof.csv'
        )
      end
    end

    context 'when the proof is associated with a label' do
      let(:data) { super().merge(label:) }
      let(:label) do
        instance_double(CfaSecurityControls::Hyperproof::Entities::Label,
                        id: 'f9d986a0-48a3-4264-b04a-ad92bd30c635',
                        name: 'Test Label')
      end

      before do
        stubs.post("labels/#{label.id}/proof") { [201, {}, response] }
      end

      it 'creates a proof with a label' do
        expect(client.create_proof(**data)).to eq(response)
      end
    end
  end

  describe '#create_proof_version' do
    let(:data) { { id: '309e2191-75d7-4f8b-8750-7c852e7a77ad', name: 'proof.csv', file: '/path/to/proof.csv' } }
    let(:response) { { id: '309e2191-75d7-4f8b-8750-7c852e7a77ad', name: 'proof.csv', version: 2 } }
    let(:file) { instance_double(Faraday::UploadIO) }

    before do
      allow(Faraday::UploadIO).to receive(:new).and_return(file)
      allow(Marcel::MimeType).to receive(:for).and_return('text/csv')
      stubs.post("proof/#{data[:id]}/versions") { [201, {}, response] }
    end

    it 'creates a new version of an existing proof' do
      expect(client.create_proof_version(**data)).to eq(response)
    end
  end

  describe '#proofs' do
    let(:first) { { data: [{ id: 'proof1' }, { id: 'proof2' }], nextToken: 'nextpage' } }
    let(:second) { { data: [{ id: 'proof3' }, { id: 'proof4' }], nextToken: nil } }
    let(:response) { first[:data] + second[:data] }

    before do
      stubs.get('/proof') do |env|
        env.params['nextToken'] ? [200, {}, second] : [200, {}, first]
      end
    end

    context 'when no block is given' do
      it 'returns all proofs' do
        expect(client.proofs).to eq(response)
      end
    end

    context 'when a block is given' do
      it 'yields each proof to the block' do
        results = []
        client.proofs { |proof| results << proof[:id] }
        expect(results).to eq(%w[proof1 proof2 proof3 proof4])
      end
    end
  end

  describe '#auth_token' do
    before do
      stub_const('ENV', {
                   'HYPERPROOF_CLIENT_ID' => 'client_id',
                   'HYPERPROOF_CLIENT_SECRET' => 'client_secret'
                 })
    end

    context 'when the credentials are invalid' do
      let(:response) do
        conn.post('/oauth/token')
      end

      before do
        stubs.post('/oauth/token') { [403, {}, {}] }

        allow(Faraday).to receive(:post)
          .with('https://accounts.hyperproof.app/oauth/token', any_args)
          .and_return(response)
      end

      it 'raises an error' do
        expect { client.send(:auth_token) }.to \
          raise_error(
            CfaSecurityControls::Hyperproof::Clients::Hyperproof::Unauthorized
          )
      end
    end

    context 'when the credentials are valid' do
      let(:response) do
        conn.post('/oauth/token')
      end

      before do
        stubs.post('/oauth/token') do
          [200, {}, { access_token: 'rspectoken' }.to_json]
        end

        allow(Faraday).to receive(:post)
          .with('https://accounts.hyperproof.app/oauth/token', any_args)
          .and_return(response)
      end

      it 'returns a valid token' do
        expect(client.send(:auth_token)).to eq('rspectoken')
      end
    end

    context 'when no credentials are provided' do
      before do
        stub_const('ENV', {})
      end

      it 'raises an error' do
        expect { client.send(:auth_token) }.to raise_error(
          CfaSecurityControls::Hyperproof::Clients::Hyperproof::Unauthorized,
          'Missing Hyperproof credentials'
        )
      end
    end
  end
end
