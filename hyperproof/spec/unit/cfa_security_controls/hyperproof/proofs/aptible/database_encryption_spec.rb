# frozen_string_literal: true

RSpec.describe CfaSecurityControls::Hyperproof::Proofs::Aptible::DatabaseEncryption do
  subject(:proof) { described_class.new }

  let(:client) { instance_double(CfaSecurityControls::Hyperproof::Clients::Aptible) }

  before do
    allow(CfaSecurityControls::Hyperproof::Clients::Aptible).to receive(:new).and_return(client)
  end

  it_behaves_like 'a proof'

  describe '#collect' do
    let(:data) { [] }

    before do
      allow(client).to receive(:databases).and_return(data)
    end

    context 'when there are no databases' do
      it 'returns an empty array' do
        expect(proof.collect).to eq([])
      end
    end

    context 'when there are databases' do
      let(:data) do
        [
          instance_double(
            Aptible::Api::Database,
            id: 'db1', handle: 'test-db', type: 'postgres', status: 'provisioned',
            disk: instance_double(Aptible::Api::Disk, filesystem: 'ecryptfs', key_bytes: 32)
          ),
          instance_double(
            Aptible::Api::Database,
            id: 'db2', handle: 'rspec-db', type: 'redis', status: 'provisioned',
            disk: instance_double(Aptible::Api::Disk, filesystem: 'ecryptfs', key_bytes: 32)
          )
        ]
      end

      it 'returns an array of databases' do
        expect(proof.collect).to eq(
          [
            {
              id: 'db1', name: 'test-db', type: 'postgres',
              status: 'provisioned', filesystem: 'ecryptfs', key_bytes: 32
            },
            {
              id: 'db2', name: 'rspec-db', type: 'redis',
              status: 'provisioned', filesystem: 'ecryptfs', key_bytes: 32
            }
          ]
        )
      end
    end
  end
end
