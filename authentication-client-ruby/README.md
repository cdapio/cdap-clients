authentication-client-ruby
==========================

The Authentication Client Ruby API is for fetching the access token from the authentication server.

## Supported Actions

 - fetch a access token from the authentication server with credentials, which are supported by the active
 authentication mechanism;
 - check is the authentication enabled in the gateway server.

## Usage

 To use the Authentication Client Ruby API, include this gem in your Gemfile:

 ```
 gem 'authentication-client-ruby'
 ```

 If you use gem outside Rails, you should require gem files in your application files:

 ```
 require 'authentication-client-ruby'
 ```

## Example

 Create a ```CDAPIngest::AuthenticationClient``` instance.
 Set the connection parameters: authentication server host; authentication server host port; SSL mode:

 ```
 authentication_client.set_connection_info('localhost',10000, true)
 ```

 Create the configuration file:
 
 ```
 # config/auth.yml
 username: 'user'
 password: 'secret'
 ssl_cert_check: true
 ```  
 
 Load configuration from file:
 
 ```
 authentication_client.configure('config/auth.yml')
 ```
 
 Or set the required fields in the ```AuthenticationClient``` object:
 ```
 
 authentication_client.username = "admin"
 authentication_client.password = "secret"
 authentication_client.ssl_cert_check = true
 ```
 
 Check if authentication is enabled in the gateway server:
 
 ```
  is_enabled = authentication_client.is_auth_enabled
 ``` 
                      
 Retrieve the access token from the authentication server:
 
 ```
 token = authentication_client.get_access_token
 ```

## Additional Notes

All methods from the ```AuthenticationClient``` throw exceptions using response code analysis from the
 gateway server. These exceptions help determine if the request was processed successfully or not.

 In the case of a **200 OK** response, no exception will be thrown; other cases will throw these exceptions:

```
  400:
      'The request had a combination of parameters that is not recognized'
  401:
      'Invalid username or password'
  403:
      'The request was authenticated but the client does not have permission'
  404:
      'The request did not address any of the known URIs'
  405:
      'A request was received with a method not supported for the URI'
  409:
      'A request could not be completed due to a conflict with the current resource state'
  500:
      'An internal error occurred while processing the request'
  501:
      'A request contained a query that is not supported by this API'
```

## Testing

To run RSpec tests, run ```rspec``` command in your shell.
