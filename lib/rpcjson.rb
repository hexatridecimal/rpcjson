require 'net/http'
require 'uri'
require 'json'

module RPC
  module JSON
    class Client
      class Error < RuntimeError
        attr_accessor :error
        def initialize(error)
          @error = error
        end
      end

      def initialize(url, version = 2.0)
        @id = 1
        @uri = URI.parse(url)
        @version = version
      end

      def method_missing(func, *args)
        json = {
          # jsonrpc
          # A String specifying the version of the JSON-RPC protocol. MUST be exactly "2.0". 
          'jsonrpc' => @version.to_s,
          # method
          # A String containing the name of the method to be invoked.
          'method' => func,
          # id
          # An identifier established by the Client that MUST contain a String, Number, or NULL value if included. If it is not included it is assumed to be a notification. The value SHOULD normally not be Null [1] and Numbers SHOULD NOT contain fractional parts [2]
          'id' => @id
        }

        # 1.0/1.1:
        # params - An Array of objects to pass as arguments to the method. 
        # 2.0:
        # params
        # A Structured value that holds the parameter values to be used during the invocation of the method. This member MAY be omitted.

        # params are expected always in 1.0/1.1. Not required in 2.0.
        if @version < 2.0 or (args != nil and args.length != 0)
          json['params'] = args
        end

        body = JSON(json)
        # puts "Sending: #{body}"

        http = Net::HTTP.new(@uri.host, @uri.port)
        request = Net::HTTP::Post.new(@uri.request_uri)
        if @uri.user != nil
          request.basic_auth(@uri.user, @uri.password)
        end
        request.body = body
        response = http.request(request)
        answer = JSON( response.body )

        # p answer 

        # 1.0/1.1
        # jsonrpc: NOT INCLUDED
        # 2.0 
        # jsonrpc: 
        # A String specifying the version of the JSON-RPC protocol. MUST be exactly "2.0".
        if answer['jsonrpc'] == nil
          if @version >= 2.0
            STDERR.puts "Error: We're configured to use JSON-RPC #{@version}, but the server appears to be using an older implementation."
          end
        else
          if answer['jsonrpc'].to_f < @version
            STDERR.puts "Error: We're configured to use JSON-RPC #{@version}, but the server appears to be using #{answer['jsonrpc']}"
          elsif answer['jsonrpc'].to_f > @version
            STDERR.puts "Error: We're configured to use JSON-RPC #{@version}, but the server appears to be using #{answer['jsonrpc']}"
          end
        end

        # 1.0/1.1
        # error - An Error object if there was an error invoking the method. It must be null if there was no error. 
        # 2.0
        # error
        # This member is REQUIRED on error.
        # This member MUST NOT exist if there was no error triggered during invocation.
        # The value for this member MUST be an Object as defined in section 5.1.

        # It will be nil in either case if there was no error.
        if answer['error'] != nil
          if @version >= 2.0
            raise Error.new(answer['error']), answer['error']['message']
          else
            # No standard for < 2.0 error objects.
            # Bitcoind is 1.1 and seems to follow 2.0 standard, other clients?
            raise Error.new(answer['error']), 'JSON-RPC Error'
          end
        end

        @id += 1

        # 1.0
        # result - The Object that was returned by the invoked method. This must be null in case there was an error invoking the method. 
        # 2.0
        # result
        # This member is REQUIRED on success.
        # This member MUST NOT exist if there was an error invoking the method.
        # The value of this member is determined by the method invoked on the Server. 
        return answer['result']
      end
    end
  end
end
