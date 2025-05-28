# frozen_string_literal: true

RSpec.describe CfaSecurityControls::Hyperproof::Clients::Aptible do
  subject(:client) { described_class.new }

  let(:sso_token_data) do
    { Aptible::Auth.configuration.root_url => 'thisIsATestToken' }.to_json
  end

  describe '#databases' do
    let(:databases) { [instance_double(Aptible::Api::Database)] }

    before do
      allow(File).to receive(:exist?).with(described_class::TOKEN_FILE).and_return(true)
      allow(File).to receive(:read).with(described_class::TOKEN_FILE).and_return(sso_token_data)
      stub_const('ENV', {})
      allow(Aptible::Api::Database).to receive(:all).and_return(databases)
    end

    it 'retrieves all databases' do
      expect(client.databases).to eq(databases)
    end
  end

  describe '#token' do
    context 'when no valid credentials are found' do
      before do
        allow(File).to receive(:exist?).with(described_class::TOKEN_FILE).and_return(false)
        stub_const('ENV', {})
      end

      it 'raises an error' do
        expect { client.send(:token) }.to raise_error(described_class::InvalidCredentials)
      end
    end

    context 'when basic auth credentials are found' do
      let(:token) { instance_double(Aptible::Auth::Token) }

      before do
        stub_const('ENV', {
                     'APTIBLE_USERNAME' => 'rspec',
                     'APTIBLE_PASSWORD' => 'rspecPassw0rd!'
                   })
        allow(Aptible::Auth::Token).to receive(:create).and_return(token)
      end

      it 'returns the basic auth token' do
        expect(client.send(:token)).to eq(token)
      end
    end

    context 'when an sso token is found' do
      before do
        allow(File).to receive(:exist?).with(described_class::TOKEN_FILE).and_return(true)
        allow(File).to receive(:read).with(described_class::TOKEN_FILE).and_return(sso_token_data)
        stub_const('ENV', {})
      end

      it 'returns the sso token' do
        expect(client.send(:token)).to eq('thisIsATestToken')
      end
    end
  end

  describe '#sso_token' do
    let(:exists) { true }

    before do
      allow(File).to receive(:exist?).with(described_class::TOKEN_FILE).and_return(exists)
      allow(File).to receive(:read).with(described_class::TOKEN_FILE).and_return(sso_token_data)
    end

    context 'when a valid token exists' do
      it 'returns the token' do
        expect(client.send(:sso_token)).to eq('thisIsATestToken')
      end
    end

    context 'when a valid token does not exist' do
      let(:sso_token_data) { { 'https://bad.rspec' => 'thisIsABadToken' }.to_json }

      it 'returns false' do
        expect(client.send(:sso_token)).to be(false)
      end
    end

    context 'when the token file does not exist' do
      let(:exists) { false }

      it 'returns false' do
        expect(client.send(:sso_token)).to be(false)
      end
    end
  end

  describe '#basic_auth_token' do
    let(:password) { 'rspecPassw0rd!' }
    let(:username) { 'rspec' }

    before do
      env = {}
      env['APTIBLE_USERNAME'] = username if username
      env['APTIBLE_PASSWORD'] = password if password
      stub_const('ENV', env)
    end

    context 'when no username is set' do
      let(:username) { nil }

      it 'returns false' do
        expect(client.send(:basic_auth_token)).to be(false)
      end
    end

    context 'when no password is set' do
      let(:password) { nil }

      it 'returns false' do
        expect(client.send(:basic_auth_token)).to be(false)
      end
    end

    context 'when no username or password is set' do
      let(:password) { nil }
      let(:username) { nil }

      it 'returns false' do
        expect(client.send(:basic_auth_token)).to be(false)
      end
    end

    context 'when username and password are set' do
      let(:token) { instance_double(Aptible::Auth::Token) }

      before do
        allow(Aptible::Auth::Token).to receive(:create).and_return(token)
      end

      it 'returns a new token' do
        expect(client.send(:basic_auth_token)).to eq(token)
      end
    end

    context 'when the credentials are invalid' do
      before do
        allow(Aptible::Auth::Token).to receive(:create)
          .and_raise(OAuth2::Error.new('rspec error'))
      end

      it 'returns false if an OAuth2::Error is raised' do
        expect(client.send(:basic_auth_token)).to be(false)
      end
    end
  end
end
