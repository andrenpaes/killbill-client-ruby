require 'cgi'
require 'net/https'

module KillBillClient
  class API
    module Net
      module HTTPAdapter
        # A hash of Net::HTTP settings configured before the request.
        #
        # @return [Hash]
        def net_http
          @net_http ||= {}
        end

        # Used to store any Net::HTTP settings.
        #
        # @example
        #   KillBillClient::API.net_http = {
        #     :verify_mode => OpenSSL::SSL::VERIFY_PEER,
        #     :ca_path     => "/etc/ssl/certs",
        #     :ca_file     => "/opt/local/share/curl/curl-ca-bundle.crt"
        #   }
        attr_writer :net_http

        private

        METHODS = {
            :head => ::Net::HTTP::Head,
            :get => ::Net::HTTP::Get,
            :post => ::Net::HTTP::Post,
            :put => ::Net::HTTP::Put,
            :delete => ::Net::HTTP::Delete
        }

        def request(method, relative_uri, options = {})
          head = headers.dup
          head.update options[:head] if options[:head]
          head.delete_if { |_, value| value.nil? }

          uri = base_uri + URI.escape(relative_uri)

          if options[:params] && !options[:params].empty?
            pairs = options[:params].map { |key, value|
              "#{CGI.escape key.to_s}=#{CGI.escape value.to_s}"
            }
            uri += "?#{pairs.join '&'}"
          end
          request = METHODS[method].new uri.request_uri, head

          # Configure auth, if enabled
          if KillBillClient.api_key and KillBillClient.api_secret
            request.basic_auth(*[KillBillClient.api_key, KillBillClient.api_secret].flatten[0, 2])
          end

          if options[:body]
            request['Content-Type'] = content_type
            request.body = options[:body]
          end
          if options[:etag]
            request['If-None-Match'] = options[:etag]
          end
          if options[:locale]
            request['Accept-Language'] = options[:locale]
          end

          # Add auditing headers, if needed
          if options[:user]
            request['X-Killbill-CreatedBy'] = options[:user]
          end
          if options[:reason]
            request['X-Killbill-Reason'] = options[:reason]
          end
          if options[:comment]
            request['X-Killbill-Comment'] = options[:comment]
          end

          http = ::Net::HTTP.new uri.host, uri.port
          http.use_ssl = uri.scheme == 'https'
          net_http.each_pair { |key, value| http.send "#{key}=", value }

          if KillBillClient.logger
            KillBillClient.log :info, '===> %s %s' % [request.method, uri]
            headers = request.to_hash
            headers['authorization'] &&= ['Basic [FILTERED]']
            KillBillClient.log :debug, headers.inspect
            if request.body && !request.body.empty?
              KillBillClient.log :debug, XML.filter(request.body)
            end
            start_time = Time.now
          end

          response = http.start { http.request request }
          code = response.code.to_i

          if KillBillClient.logger
            #noinspection RubyScope
            latency = (Time.now - start_time) * 1_000
            level = case code
                      when 200...300 then
                        :info
                      when 300...400 then
                        :warn
                      when 400...500 then
                        :error
                      else
                        :fatal
                    end
            KillBillClient.log level, '<=== %d %s (%.1fms)' % [
                code,
                response.class.name[9, response.class.name.length].gsub(
                    /([a-z])([A-Z])/, '\1 \2'
                ),
                latency
            ]
            KillBillClient.log :debug, response.to_hash.inspect
            KillBillClient.log :debug, response.body if response.body
          end

          case code
            when 200...300 then
              response
            else
              raise ERRORS[code].new request, response
          end
        end
      end
    end

    extend Net::HTTPAdapter
  end
end