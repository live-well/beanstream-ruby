require 'rest-client'
require 'base64'
require 'json'

module Beanstream
  class Transaction
    def encode(merchant_id, api_key)
      str = "#{merchant_id}:#{api_key}"
      Base64.encode64(str).delete("\n")
    end

    def transaction_post(method, url_path, merchant_id, api_key, data = {})
      enc = encode(merchant_id, api_key)

      path = Beanstream.api_host_url + url_path

      req_params = {
        verify_ssl:   OpenSSL::SSL::VERIFY_PEER,
        ssl_ca_file:  Beanstream.ssl_ca_cert,
        timeout:      Beanstream.timeout,
        open_timeout: Beanstream.open_timeout,
        headers:      {
          authorization: "Passcode #{enc}",
          content_type:  'application/json'
        },
        method:       method,
        url:          path,
        payload:      data.to_json
      }

      if @sub_merchant_id
        req_params[:headers][:'Sub-Merchant-Id'] = @sub_merchant_id
      end

      begin
        result = RestClient::Request.execute(req_params)
        JSON.parse(result)
      rescue RestClient::ExceptionWithResponse => ex
        if ex.response
          raise handle_api_error(ex)
        else
          raise handle_restclient_error(ex)
        end
      rescue RestClient::Exception => ex
        raise handle_restclient_error(ex)
      end
    end

    def handle_api_error(ex)
      http_status_code = ex.http_code
      message = ex.message
      code = 0
      category = 0

      begin
        obj = JSON.parse(ex.http_body)
        obj = Util.symbolize_names(obj)
        code = obj[:code]
        category = obj[:category]
        message = obj[:message]
      rescue JSON::ParserError
        puts 'Error parsing json error message'
      end

      exception_type = case http_status_code
                       when 302
                         message = "Redirection for IOP and 3dSecure not supported by the Beanstream SDK yet. #{message}"
                         InvalidRequestException
                       when 400
                         InvalidRequestException
                       when 401
                         UnauthorizedException
                       when 402
                         BusinessRuleException
                       when 403
                         ForbiddenException
                       when 404
                         InvalidRequestException
                       when 405
                         InvalidRequestException
                       when 415
                         InvalidRequestException
                       when 500..599
                         InternalServerException
                       else
                         BeanstreamException
                       end

      raise exception_type.new(code, category, message, http_status_code)
    end

    def handle_restclient_error(exception)
      case exception
      when RestClient::RequestTimeout
        message = 'Could not connect to Beanstream'

      when RestClient::ServerBrokeConnection
        message = 'The connection to the server broke before the request completed.'

      when RestClient::SSLCertificateNotVerified
        message = "Could not verify Beanstream's SSL certificate. " \
          'Please make sure that your network is not intercepting certificates.'

      when SocketError
        message = 'Unexpected error communicating when trying to connect to Beanstream. '

      else
        message = 'Unexpected error communicating with Beanstream. '

      end

      raise APIConnectionError.new(message + "\n\n(Network error: #{exception.message})")
    end
  end
end
