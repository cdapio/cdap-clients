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

require 'httparty'
require 'yaml'

module CDAPIngest
  ###
  # The helper class for providing http requests
  class Rest
    include HTTParty

    def request(method, url, options = {}, ssl_cert_check, &block)
      method.downcase!
      # send request
      HTTParty::Basement.default_options.update(verify: ssl_cert_check)
      method == 'get' ? response =
          self.class.get(url, options, &block ) : fail('Unknown http method')
      # process response
      unless response.response.is_a?(Net::HTTPSuccess)
        error = ResponseError.new response
        case response.code
        when 400
          fail error, 'The request had a combination of
                          parameters that is not recognized'
        when 401
          fail error, 'Invalid username or password' unless url =~ /auth_uri/
        when 403
          fail error, 'The request was authenticated but
                          the client does not have permission'
        when 404
          fail error, 'The request did not address any of the known URIs'
        when 405
          fail error, 'A request was received with a
                       method not supported for the URI'
        when 409
          fail error, 'A request could not be completed due to a conflict
                          with the current resource state'
        when 500
          fail error, 'An internal error occurred while processing the request'
        when 501
          fail error, 'A request contained a query that
                       is not supported by this API'
        else
          fail error, 'Unknown http error'
        end
      end
      response
    end
  end
end
