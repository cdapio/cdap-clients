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

module CDAPIngest
  ###
  # The client interface to interact with services provided by stream endpoint.
  class AuthenticationClient
    attr_reader :rest
    attr_accessor :username
    attr_accessor :password
    attr_accessor :ssl_cert_check

    SPARSE_TIME_IN_MILLIS = 5000

    def initialize
      @rest = Rest.new
      @base_url = nil
      @auth_url = nil
      @is_auth_enabled = nil
      @access_token = nil
      @ssl_cert_check = false
    end

    def configure(path)
      config = YAML.load_file(path)
      @username = config['username']
      @password = config['password']
      @ssl_cert_check = config['ssl_cert_check']
    end

    def set_connection_info(host, port, ssl)
      if @base_url
        fail IllegalStateException.new, 'Connection info is already configured!'
      end
      protocol = ssl ? 'https' : 'http'
      @base_url = "#{protocol}://#{host}:#{port}"
    end

    def fetch_auth_url
      req = rest.request 'get', @base_url + '/auth_uri', @ssl_cert_check
      auth_url_array = req ['auth_uri']
      if  auth_url_array.length > 1
        @auth_url = auth_url_array [Random.rand(auth_url_array.length - 1)]
      else
        @auth_url = auth_url_array[0]
      end
    end

    def get_access_token
      unless auth_enabled?
        fail ArgumentError.new, 'Authentication is disabled
                                 in the gateway server.'
      end
      if  @access_token.nil? || token_expired?
        request_time = Time.now.to_f * 1000
        options = { basic_auth: { username: @username, password: @password } }
        response = rest.request('get', @auth_url, options, @ssl_cert_check)
        token_value = response['access_token']
        token_type  = response['token_type']
        expires_in = response['expires_in']
        @expiration_time  = request_time + expires_in - SPARSE_TIME_IN_MILLIS
        @access_token = AccessToken.new(token_value, token_type, expires_in,)
      end
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
  end
end

class IllegalStateException < Exception; end
