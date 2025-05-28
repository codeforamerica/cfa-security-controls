# frozen_string_literal: true

RSpec.describe CfaSecurityControls::Hyperproof::Entities::Proof do
  subject(:proof) { described_class.new('rspec.csv') }

  let(:client) { instance_double(CfaSecurityControls::Hyperproof::Clients::Hyperproof) }

  before do
    allow(CfaSecurityControls::Hyperproof::Clients::Hyperproof).to receive(:new).and_return(client)
  end

  describe '#create' do
    let(:data) { [] }
    let(:response) { { id: 'proof_id', filename: 'rspec.csv' } }

    before do
      allow(client).to receive_messages(create_proof: response)
      if data.empty?
        allow(client).to receive(:proofs).and_return(data)
      else
        data.each do |d|
          allow(client).to receive(:proofs).and_yield(d)
        end
      end
    end

    context 'when the proof does not exist' do
      it 'creates a new proof' do
        proof.create('/tmp/path/rspec.csv')

        expect(client).to have_received(:create_proof)
          .with(file: '/tmp/path/rspec.csv', label: nil, name: 'rspec.csv')
      end

      it 'returns the new proof' do
        expect(proof.create('/tmp/path/rspec.csv')).to eq(response)
      end
    end

    context 'when the proof already exists' do
      let(:data) { [{ id: 'proof_id', filename: 'rspec.csv' }] }

      before do
        allow(client).to receive_messages(create_proof_version: response)
      end

      it 'does not create a new proof' do
        proof.create('/tmp/path/rspec.csv')

        expect(client).not_to have_received(:create_proof)
      end

      it 'creates a new version' do
        proof.create('/tmp/path/rspec.csv')

        expect(client).to have_received(:create_proof_version)
          .with(id: 'proof_id', file: '/tmp/path/rspec.csv', name: 'rspec.csv')
      end

      it 'returns the existing proof' do
        expect(proof.create('/tmp/path/rspec.csv')).to eq(data[0])
      end
    end
  end

  describe '#exists?' do
    let(:data) { [{ id: 'proof_id1', filename: 'existing.xlsx' }] }

    before do
      if data.empty?
        allow(client).to receive(:proofs).and_return(data)
      else
        data.each do |d|
          allow(client).to receive(:proofs).and_yield(d)
        end
      end
    end

    context 'when the proof exists' do
      let(:data) { super() + [{ id: 'proof_id2', filename: 'rspec.csv' }] }

      it 'returns true' do
        expect(proof.exists?).to be true
      end
    end

    context 'when the proof does not exist' do
      it 'returns false' do
        expect(proof.exists?).to be false
      end
    end

    context 'when no proofs exists' do
      let(:data) { [] }

      it 'returns false' do
        expect(proof.exists?).to be false
      end
    end
  end

  describe '#id' do
    let(:data) { [] }

    before do
      if data.empty?
        allow(client).to receive(:proofs).and_return(data)
      else
        data.each do |d|
          allow(client).to receive(:proofs).and_yield(d)
        end
      end
    end

    context 'when the proof exists' do
      let(:data) { [{ id: 'proof_id', filename: 'rspec.csv' }] }

      it 'returns the ID of the proof' do
        expect(proof.id).to eq('proof_id')
      end
    end

    context 'when the proof does not exist' do
      it 'raises an error' do
        expect { proof.id }.to \
          raise_error(CfaSecurityControls::Hyperproof::Entities::Proof::NotFound)
      end
    end
  end

  describe '#version' do
    let(:data) { [] }

    before do
      if data.empty?
        allow(client).to receive(:proofs).and_return(data)
      else
        data.each do |d|
          allow(client).to receive(:proofs).and_yield(d)
        end
      end
    end

    context 'when the proof exists' do
      let(:data) { [{ id: 'proof_id', filename: 'rspec.csv', version: 2 }] }

      it 'returns the ID of the proof' do
        expect(proof.version).to eq(2)
      end
    end

    context 'when the proof does not exist' do
      it 'raises an error' do
        expect { proof.version }.to \
          raise_error(CfaSecurityControls::Hyperproof::Entities::Proof::NotFound)
      end
    end
  end
end
