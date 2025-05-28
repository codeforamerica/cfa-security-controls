# frozen_string_literal: true

RSpec.describe CfaSecurityControls::Hyperproof::Writer do
  subject(:writer) { described_class.new('/tmp') }

  describe '#write' do
    let(:data) { [{ name: 'John', age: 30 }, { name: 'Jane', age: 25 }] }
    let(:csv) { instance_double(CSV).tap { |i| allow(i).to receive(:<<) } }

    before do
      allow(CSV).to receive(:open).and_yield(csv)
    end

    it 'writes data to a CSV file with the correct filename' do
      result = writer.write('test_file', data)

      expect(result).to eq('/tmp/test_file.csv')
    end

    it 'writes the correct headers to the CSV file' do
      writer.write('test_file', data)

      expect(csv).to have_received(:<<).with(%i[name age])
    end

    it 'writes the correct data rows to the CSV file' do
      writer.write('test_file', data)

      data.each do |row|
        expect(csv).to have_received(:<<).with(row.values)
      end
    end

    context 'when there is no data' do
      let(:data) { [] }

      it 'creates an empty file' do
        writer.write('empty_file', data)

        expect(csv).not_to have_received(:<<)
      end
    end
  end
end
