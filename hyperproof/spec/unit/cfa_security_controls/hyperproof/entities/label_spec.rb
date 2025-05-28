# frozen_string_literal: true

RSpec.describe CfaSecurityControls::Hyperproof::Entities::Label do
  subject(:label) { described_class.new('Test Label') }

  let(:client) { instance_double(CfaSecurityControls::Hyperproof::Clients::Hyperproof) }

  before do
    allow(CfaSecurityControls::Hyperproof::Clients::Hyperproof).to receive(:new).and_return(client)
  end

  describe '#create' do
    let(:data) { [] }
    let(:response) { { id: 'label_id', name: 'Test Label' } }

    before do
      allow(client).to receive_messages(labels: data, create_label: response)
    end

    context 'when the label does not exist' do
      it 'creates a new label' do
        label.create

        expect(client).to have_received(:create_label).with(name: 'Test Label')
      end

      it 'returns the new label' do
        expect(label.create).to eq(response)
      end
    end

    context 'when the label already exists' do
      let(:data) { [{ id: 'label_id', name: 'Test Label' }] }

      it 'does not create a new label' do
        label.create

        expect(client).not_to have_received(:create_label)
      end

      it 'returns the existing label' do
        expect(label.create).to eq(data[0])
      end
    end
  end

  describe '#exists?' do
    let(:data) { [{ id: 'label_id1', name: 'Existing Label' }] }

    before do
      allow(client).to receive_messages(labels: data)
    end

    context 'when the label exists' do
      let(:data) { super() + [{ id: 'label_id2', name: 'Test Label' }] }

      it 'returns true' do
        expect(label.exists?).to be true
      end
    end

    context 'when the label does not exist' do
      it 'returns false' do
        expect(label.exists?).to be false
      end
    end

    context 'when no labels exists' do
      let(:data) { [] }

      it 'returns false' do
        expect(label.exists?).to be false
      end
    end
  end

  describe '#id' do
    let(:data) { [] }

    before do
      allow(client).to receive_messages(labels: data)
    end

    context 'when the label exists' do
      let(:data) { [{ id: 'label_id', name: 'Test Label' }] }

      it 'returns the ID of the label' do
        expect(label.id).to eq('label_id')
      end
    end

    context 'when the label does not exist' do
      it 'raises an error' do
        expect { label.id }.to \
          raise_error(CfaSecurityControls::Hyperproof::Entities::Label::NotFound)
      end
    end
  end
end
