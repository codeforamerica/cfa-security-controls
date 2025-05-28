# frozen_string_literal: true

RSpec.describe CfaSecurityControls::Hyperproof::Proofs::Proof do
  subject(:proof) { described_class.new }

  describe '#label' do
    it 'raises NotImplementedError' do
      expect { proof.label }.to raise_error(NotImplementedError)
    end
  end

  describe '#name' do
    it 'raises NotImplementedError' do
      expect { proof.name }.to raise_error(NotImplementedError)
    end
  end

  describe '#collect' do
    it 'does implement a collect method' do
      expect(proof.respond_to?(:collect)).to be false
    end
  end

  describe '#write' do
    let(:writer) { instance_double(CfaSecurityControls::Hyperproof::Writer) }

    let(:concrete) do
      Class.new(CfaSecurityControls::Hyperproof::Proofs::Proof) do
        def name
          'Concrete Proof'
        end

        def collect
          []
        end
      end.new
    end

    before do
      allow(writer).to receive(:write)
    end

    it 'writes the collected evidence to a file' do
      concrete.write(writer)

      expect(writer).to have_received(:write).with('Concrete Proof', [])
    end
  end
end
