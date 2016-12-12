#  Copyright © 2014 Cask Data, Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License"); you may not
#  use this file except in compliance with the License. You may obtain a copy of
#  the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#  License for the specific language governing permissions and limitations under
#  the License.

require 'spec_helper'

describe CDAP::AuthenticationClient do
  let(:authentication_client) { CDAP::AuthenticationClient.new }
  before do
    authentication_client.set_connection_info('127.0.0.1', 11_000, false)
  end

  it 'instance check' do
    VCR.insert_cassette('authentication_client')
    expect(authentication_client).to be_a CDAP::AuthenticationClient
    VCR.eject_cassette
  end

  it { expect(CDAP::AuthenticationClient).to respond_to(:new) }

  it { expect(authentication_client).to respond_to(:get_access_token) }

  it 'get access token test' do
    VCR.insert_cassette('authentication_client_get_auth_enabled')
    config = YAML.load_file('spec/auth.yml')
    authentication_client.configure(config)
    authentication_client.auth_enabled?
    VCR.eject_cassette
    VCR.insert_cassette('authentication_client_get_access_token')
    token = authentication_client.get_access_token
    expect(token.class).to eq CDAP::AccessToken
    expect(token.value).to be_a String
    expect(token.token_type).to eq 'Bearer'
    expect(token.expires_in).to eq 86_400
    VCR.eject_cassette
  end

  it 'invalid credentials test' do
    VCR.insert_cassette('authentication_client_get_auth_enabled')
    authentication_client.auth_enabled?
    VCR.eject_cassette
    VCR.insert_cassette(
      'invalid_credentials_authentication_client_get_access_token')
    config = YAML.load_file('spec/auth_fail.yml')
    authentication_client.configure(config)
    expect { authentication_client.get_access_token }.to raise_error(
      HTTParty::ResponseError,
      'Invalid username or password')
    VCR.eject_cassette
  end

  it { expect(authentication_client).to respond_to(:auth_enabled?) }

  it 'is authentication enabled test' do
    VCR.insert_cassette('authentication_client_get_auth_enabled')
    config = YAML.load_file('spec/auth.yml')
    authentication_client.configure(config)
    is_enabled = authentication_client.auth_enabled?
    expect(is_enabled).to be_truthy
    VCR.eject_cassette
  end

  it 'load credentials test' do
    config = YAML.load_file('spec/auth.yml')
    authentication_client.configure(config)
    expect(authentication_client.username).to eq 'user'
    expect(authentication_client.password).to eq 'secret'
    expect(authentication_client.ssl_cert_check).to eq true
  end
end
