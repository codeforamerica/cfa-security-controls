# frozen_string_literal: true

RSpec.shared_examples 'a proof' do
  subject(:proof) { described_class.new }

  it 'has a name' do
    expect(proof.name.empty?).to be false
  end

  it 'has a label' do
    expect(proof.label.empty?).to be false
  end

  it 'defines a collect method' do
    expect(proof.respond_to?(:collect)).to be true
  end
end
