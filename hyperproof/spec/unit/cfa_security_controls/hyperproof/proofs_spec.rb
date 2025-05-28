# frozen_string_literal: true

RSpec.describe CfaSecurityControls::Hyperproof::Proofs do
  describe '.proofs' do
    context 'when no proof classes are defined' do
      before { allow(described_class).to receive(:constants).and_return([]) }

      it 'returns an empty array when no proof classes are defined' do
        expect(described_class.proofs).to eq([])
      end
    end

    context 'when proof classes are defined' do
      let(:non_proof_class) { Class.new }
      let(:nested_module) { Module.new }

      let(:proof_class) do
        Class.new do
          def collect; end
        end
      end

      let(:nested_class) do
        Class.new do
          def collect; end
        end
      end

      before do
        stub_const('CfaSecurityControls::Hyperproof::Proofs::TestProof', proof_class)
        stub_const('CfaSecurityControls::Hyperproof::Proofs::TestNonProof', non_proof_class)
        stub_const('CfaSecurityControls::Hyperproof::Proofs::Nested', nested_module)
        stub_const('CfaSecurityControls::Hyperproof::Proofs::Nested::TestProof', nested_class)
      end

      it 'return classes that define a collect method' do
        expect(described_class.proofs).to include(proof_class)
      end

      it 'returns nested classes that define a collect method' do
        expect(described_class.proofs).to include(nested_class)
      end

      it 'does not include classes that do not define a collect method' do
        expect(described_class.proofs).not_to include(non_proof_class)
      end
    end
  end
end
