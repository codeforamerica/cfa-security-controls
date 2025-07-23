# frozen_string_literal: true

RSpec.describe CfaSecurityControls::Hyperproof::Proofs::AWS::VolumeEncryption do
  subject(:proof) { described_class.new }

  let(:client) { instance_double(Aws::ConfigService::Client) }

  before do
    allow(Aws::ConfigService::Client).to receive(:new).and_return(client)
  end

  it_behaves_like 'a proof'

  describe '#collect' do
    let(:data) { [] }

    let(:response) do
      instance_double(
        Aws::ConfigService::Types::SelectAggregateResourceConfigResponse,
        results: data.map(&:to_json)
      )
    end

    before do
      allow(client).to receive(:select_aggregate_resource_config).and_return(response)
    end

    context 'when there are no volumes' do
      it 'returns an empty array' do
        expect(proof.collect).to eq([])
      end
    end

    context 'when there are volumes' do
      let(:data) do
        [
          {
            'accountId' => '123456789012',
            'resourceId' => 'vol-049df61146c4d7901',
            'awsRegion' => 'us-east-1',
            'availabilityZone' => 'us-east-1b',
            'resourceName' => 'rspec-test',
            'arn' => 'arn:aws:ec2:us-east-1:123456789012:volume/vol-049df61146c4d7901',
            'tags' => { 'environment' => 'test', 'project' => 'rspec' },
            'configuration' => {
              'encrypted' => true,
              'kmsKeyId' => 'arn:aws:kms:us-east-1:123456789012:key/abcd1234-56ef-78gh-90ij-klmnopqrstuv'
            }
          },
          {
            'accountId' => '123456789012',
            'resourceId' => 'vol-049df61146c4d7902',
            'awsRegion' => 'us-west-2',
            'availabilityZone' => 'us-west-2a',
            'resourceName' => 'rspec-prod',
            'arn' => 'arn:aws:ec2:us-west-2:123456789012:volume/vol-049df61146c4d7902',
            'tags' => { 'environment' => 'prod', 'project' => 'rspec' },
            'configuration' => {
              'encrypted' => true,
              'kmsKeyId' => 'arn:aws:kms:us-west-2:123456789012:key/4321dcba-56ef-78gh-90ij-klmnopqrstuv'
            }
          }
        ]
      end

      it 'returns an array of volumes' do
        expect(proof.collect).to eq(
          [
            {
              accountId: '123456789012', resourceId: 'vol-049df61146c4d7901',
              awsRegion: 'us-east-1', availabilityZone: 'us-east-1b',
              resourceName: 'rspec-test', arn: 'arn:aws:ec2:us-east-1:123456789012:volume/vol-049df61146c4d7901',
              tags: { environment: 'test', project: 'rspec' },
              encrypted: true,
              kmsKeyId: 'arn:aws:kms:us-east-1:123456789012:key/abcd1234-56ef-78gh-90ij-klmnopqrstuv'
            },
            {
              accountId: '123456789012', resourceId: 'vol-049df61146c4d7902',
              awsRegion: 'us-west-2', availabilityZone: 'us-west-2a',
              resourceName: 'rspec-prod', arn: 'arn:aws:ec2:us-west-2:123456789012:volume/vol-049df61146c4d7902',
              tags: { environment: 'prod', project: 'rspec' },
              encrypted: true,
              kmsKeyId: 'arn:aws:kms:us-west-2:123456789012:key/4321dcba-56ef-78gh-90ij-klmnopqrstuv'
            }
          ]
        )
      end
    end
  end
end
