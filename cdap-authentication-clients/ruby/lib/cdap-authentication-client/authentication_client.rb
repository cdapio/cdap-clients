#  Copyright © 2014-2015 Cask Data, Inc.
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

module CDAP
  require 'cdap-authentication-client/authentication_client_interface'
  ###
  # The client class to fetch access token from the authentication server
  class AuthenticationClient < AuthenticationClientInterface
    attr_reader :rest
    attr_reader :username
    attr_reader :password
    attr_reader :ssl_cert_check

    SPARSE_TIME_IN_MILLIS = 5000
    USERNAME_PROP_NAME = 'security_auth_client_username'
    PASSWORD_PROP_NAME = 'security_auth_client_password'

    def initialize
      @rest = AuthClientRest.new
      @ping_url = nil
      @auth_url = nil
      @is_auth_enabled = nil
      @access_token = nil
      @ssl_cert_check = false
      @credentials = [Credential.new(USERNAME_PROP_NAME, 'Username for basic authentication.', false),
                      Credential.new(PASSWORD_PROP_NAME, 'Password for basic authentication.', true)]
    end

    def configure(hash)
      if @username || @password
        fail IllegalStateException.new, 'Client is already configured!'
      end
      @username = hash['security.auth.client.username']
      @password = hash['security.auth.client.password']
      @ssl_cert_check = hash['security.auth.client.ssl_cert_check']
    end

    def get_required_credentials
      @credentials
    end

    def set_connection_info(host, port, ssl)
      if @ping_url
        fail IllegalStateException.new, 'Connection info is already configured!'
      end
      protocol = ssl ? 'https' : 'http'
      @ping_url = "#{protocol}://#{host}:#{port}/ping"
    end

    def fetch_auth_url
      req = rest.get(@ping_url, @ssl_cert_check)
      auth_urls = req ['auth_uri']
      if auth_urls.empty?
        fail AuthenticationServerNotFoundException.new 'No Authentication server to get a token from was found'
      else
        @auth_url = auth_urls.sample
      end
    end

    def get_access_token
      unless auth_enabled?
        fail ArgumentError.new, 'Authentication is disabled
                                 in the gateway server.'
      end
      if @access_token.nil? || token_expired?
        request_time = Time.now.to_f * 1000
        options = { basic_auth: { username: @username, password: @password } }
        response = rest.get(@auth_url, options, @ssl_cert_check)
        token_value = response['access_token']
        token_type  = response['token_type']
        expires_in = response['expires_in']
        @expiration_time = request_time + expires_in - SPARSE_TIME_IN_MILLIS
        @access_token = AccessToken.new(token_value, token_type, expires_in)
      end
      @access_token
    end

    def auth_enabled?
      if @is_auth_enabled.nil?
        @auth_url = fetch_auth_url
        @auth_url ? @is_auth_enabled = true : @is_auth_enabled = false
      end
      @is_auth_enabled
    end

    def token_expired?
      @expiration_time < Time.now.to_f * 1000
    end

    def invalidate_token
      @access_token = nil
    end
  end
end

class IllegalStateException < Exception; end

class AuthenticationServerNotFoundException < Exception; end
