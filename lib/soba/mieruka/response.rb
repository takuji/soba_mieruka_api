class Soba::Mieruka

  class Response
    OK = 'OK'
    NG = 'NG'
    
    def self.parse(res_body)
      doc = REXML::Document.new(res_body)
      if doc.root.attributes['result'] == 'OK'
        return Response.new(OK, doc)
      else
        errorElm = doc.root.elements['error']
        res = Response.new(NG, nil)
        res.error_code = errorElm.attributes['code']
        res.error_message = CGI.unescapeHTML(errorElm.attributes['message'])
        return res
      end
    end
    
    attr_accessor :error_code, :error_message

    def initialize(result, value, message=nil)
      @result = result
      @value = value
      @message = message
    end

    def success?
      @result != NG
    end

    attr_reader :value, :message
  end


end
