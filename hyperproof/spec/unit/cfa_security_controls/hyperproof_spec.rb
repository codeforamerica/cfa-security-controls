# frozen_string_literal: true

RSpec.describe CfaSecurityControls::Hyperproof do
  let(:writer) { instance_double(CfaSecurityControls::Hyperproof::Writer) }
  let(:proof_klass) { CfaSecurityControls::Hyperproof::Proofs::AWS::DatabaseEncryption }

  let(:proof) do
    instance_double(proof_klass, label: label, write: '/tmp/test_dir/proof_file.csv')
  end

  let(:entity) do
    instance_double(CfaSecurityControls::Hyperproof::Entities::Proof, create: true)
  end

  let(:label) do
    instance_double(CfaSecurityControls::Hyperproof::Entities::Label,
                    exists?: true, create: true)
  end

  describe '.run' do
    before do
      allow(Dir).to receive(:mktmpdir).and_yield('/tmp/test_dir')
      allow(CfaSecurityControls::Hyperproof::Writer).to receive(:new).and_return(writer)
      allow(CfaSecurityControls::Hyperproof::Proofs).to receive(:proofs).and_return([proof_klass])
      allow(proof_klass).to receive(:new).and_return(proof)
      allow(CfaSecurityControls::Hyperproof::Entities::Proof).to receive(:new).and_return(entity)
      allow(CfaSecurityControls::Hyperproof::Entities::Label).to receive(:new).and_return(label)
    end

    it 'writes the proof to a file' do
      described_class.run

      expect(proof).to have_received(:write).with(writer)
    end

    context 'when the label exists' do
      it 'does not create a new label' do
        described_class.run

        expect(label).not_to have_received(:create)
      end
    end

    context 'when the label does not exist' do
      before do
        allow(label).to receive(:exists?).and_return(false)
      end

      it 'creates a new label' do
        described_class.run

        expect(label).to have_received(:create)
      end
    end

    it 'create the new proof entity' do
      described_class.run

      expect(entity).to have_received(:create).with('/tmp/test_dir/proof_file.csv')
    end
  end
end
