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
  class AuthenticationClientInterface
    def configure(_properties)
      fail 'This method should be overridden'
    end

    def get_access_token
      fail 'This method should be overridden'
    end

    def auth_enabled?
      fail 'This method should be overridden'
    end

    def invalidate_token
      fail 'This method should be overridden'
    end

    def set_connection_info(_host, _port, _ssl)
      fail 'This method should be overridden'
    end

    def get_required_credentials
      fail 'This method should be overridden'
    end
  end
end
