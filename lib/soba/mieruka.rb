# code: utf-8

require 'digest/md5'
require 'cgi'
require 'net/http'
require 'pathname'
mieruka_dir = Pathname(File.dirname(__FILE__)) + 'mieruka'
require mieruka_dir + 'user'
require mieruka_dir + 'session'
require mieruka_dir + 'room'
require mieruka_dir + 'group'
require mieruka_dir + 'version'

module Soba
  
  class ApiResponse

    attr_reader :doc, :error_code, :error_message
    
    def initialize(res)
      @ok = false
      if res.message == 'OK'
        @doc = REXML::Document.new(res.body)
        if @doc.root.attributes['result'] == 'OK'
          @ok = true
        else
          errorElm = @doc.root.elements['error']
          @error_code = errorElm.attributes['code'].to_i
          @error_message = CGI.unescapeHTML(errorElm.attributes['message'])
        end
      end
    end

    def ok?
      return @ok
    end
    
  end

  class ApiError < StandardError
    def initialize(response)
      @error_code = response.error_code
      @error_message = response.error_message
    end
    attr_reader :error_code, :error_message
  end
  
  
  class Mieruka
    
    DEFAULT_CONFIG = {
      :api_key => '',
      :private_key => '',
      :host => 'web-api.soba-project.com',
      :port => 80,
      :base_path => '/webapi',
      :version => 1.4
    }

    def initialize(params)
      @params = DEFAULT_CONFIG.merge(params)
      @params[:base_path] += '/' + @params[:version].to_s unless @params[:version].nil?
    end

    attr_reader :token

    # Returns the URL of the application's authentication page.
    def authentication_url(back_url)
      timestamp = Time.now.to_i.to_s
      sig_base = @params[:private_key] + @params[:api_key] + back_url + timestamp
      sig = Digest::MD5.new(sig_base)
      enc_url = CGI.escape(back_url)
      "#{$HTTPS_API_ROOT}/auth?api_key=#{@params[:api_key]}&back_url=#{enc_url}&time=#{timestamp}&sig=#{sig}"
    end

    def login(params)
      required_params params, :user_name, :password
      http = ::Net::HTTP.start(@params[:host], @params[:port])
      path = @params[:base_path] + '/login'
      val = "api_key=#{@params[:api_key]}&user_name=#{CGI.escape(params[:user_name])}&password=#{params[:password]}"
      response = http.post(path, val)
      make_response(response) do |doc, res|
        @token = CGI.unescapeHTML(doc.root.elements["token"].get_text.to_s)
      end
    end
    
    def logout
      # Returns a Command object
      response = request_with_auth(:GET, '/logout')
      make_response(response) do |doc, res|
        url = CGI.unescapeHTML(doc.root.elements["url"].get_text.to_s)
      end
    end

    def create_session(params)
      required_params params, :session_name, :session_description
      response = request_with_auth(:POST, '/create_session', params)
      make_response(response) do |doc, res|
        Struct.new(:url, :soba_session_id).new(
          CGI.unescapeHTML(doc.root.elements["url"].get_text.to_s),
          CGI.unescapeHTML(doc.root.elements["soba-session-id"].get_text.to_s)
        )
      end
    end

    def join_session(params)
      required_params params, :session_id
      sid = CGI.escape(params['session_id'])
      response = request_with_auth(:GET, "/join_session?session_id=#{sid}")
      puts response.body
      make_response(response) do |doc, res|
        Struct.new(:url).new(CGI.unescapeHTML(doc.root.elements["url"].get_text.to_s))
      end
    end

    def sessions
      # Returns an Array of Session object
      response = request_with_auth(:GET, "/session_list")
      make_response(response) do |doc, res|
        doc.elements.collect('session-list-response/session-list/session') do |elm|
          Session.create_from_session_element(elm)
        end
      end
    end

    def users
      # Returns an Array of User object
      response = request_with_auth(:GET, "/user_list")
      #puts response.body
      make_response(response) do |doc, res|
        doc.elements.collect('user-list-response/user') do |elm|
          User.create_from_element(elm)
        end
      end
    end
    
    def change_password(new_password)
      response = request_with_auth(:POST, '/change_password', :newPassword => new_password)
      make_response(response)
    end

    def get_command(session_url)
      # Returns a Command object which contains a URL to create or join the session
      take_action(GetCommand)
    end
    
    def rooms(params={})
      response = request_with_auth(:GET, '/rooms', params)
      make_response(response) do |doc, res|
        doc.elements.collect('*/room') do |elm|
          Room.create_from_room_element(elm)
        end        
      end
    end
    
    def create_room(params)
      required_params params, :name, :description
      response = request_with_auth(:POST, '/create_room', params)
      make_response(response) do |doc, res|
        Room.create_from_room_element(doc.root.elements['room'])
      end
    end

    def delete_room(rid)
      response = request_with_auth(:GET, "/delete_room?rid=%s" % rid.to_s)
      make_response(response)
    end

    def groups(params={})
      response = request_with_auth(:GET, '/groups', params)
      make_response(response) do |doc, res|
        doc.elements.map('*/group') do |elm|
          res.groups << Group.create_from_element(elm)
        end        
      end
    end

    def update_user_info(params)
      #take_action(UpdateUserInfo, params)
      res = request_with_auth(:GET, '/update_user_info', params)
      return ApiResponse.new(res)
    end
    
    def command_file(params)
      required_params params, :rid
      auth = CGI.escape(Mieruka.auth_header(@token, @params[:private_key])
      return "http://%s%s/command.mkd?rid=%s&auth=%s" % [@server, @base_path, params[:rid], auth]
    end

    def create_group(params)
      required_params params, :groupName, :groupDescription, :groupAdminName, :groupAdminPassword, :mailAddress
      res = request_with_auth(:POST, '/create_group', params)
      return ApiResponse.new(res)
    end

    def create_group_member(params)
      required_params params, :newUserName, :newUserPassword, :nickname, :groupName, :groupAdminName, :groupAdminPassword
      res = request_with_auth(:POST, '/create_group_member', params)
      return ApiResponse.new(res)
    end

    def delete_group_member(params)
      required_params params, :userName, :groupName, :groupAdminName, :groupAdminPassword
      res = request_with_auth(:POST, '/delete_group_member', params)
      ApiResponse.new(res)
    end
    
    def set_pap_layout(layout)
      response = request_with_auth(:POST, '/set_pap_layout', :layout => layout)
      puts response.code
      make_response(response)
    end
    
    def get_license_usage
      response = request_with_auth(:GET, '/get_license_usage')
      make_response(response) do |doc, res|
        class << res
          attr_accessor :group, :max, :used
        end
        res.group = CGI.unescape(doc.root.elements['group'].get_text.to_s)
        res.max = doc.root.elements['max'].get_text.to_s.to_i
        res.used = doc.root.elements['used'].get_text.to_s.to_i
      end
    end
    
    def set_number_of_licenses(val)
      response = request_with_auth(:GET, "/set_number_of_licenses?value=#{val}")
      make_response(response)
    end

    #
    # Private Methods
    #
    
    private

    def make_response(http_response, &block)
      if http_response.message == 'OK'
        res = ApiResponse.new(http_response)
        if res.ok?
          if block
            block.call(res.doc, res)
          end
        else
          raise ApiError.new(res)
        end
      else
        raise http_response.message
      end      
    end

    def request_with_auth(method, path, params={})
      http = Net::HTTP.start(@params[:host], @params[:port])
      req = nil
      real_path = @params[:base_path] + path
      #params[:auth] = Mieruka.auth_header(@token, @params[:private_key])
      case method
      when :GET
        req = Mieruka::make_get_request(real_path, params)
      when :POST
        req = Mieruka::make_post_request(real_path, params)
      else
        raise 'Invalid method: ' + method
      end
      req['Authorization'] = Mieruka.auth_header(@token, @params[:private_key])
      http.request(req)
    end

    #
    # Helper Methods
    #
    
    def self.make_get_request(path, params={})
      query_params = Mieruka.make_params_string(params)
      path += '?' + query_params if query_params.length > 0
      return Net::HTTP::Get.new(path)
    end

    def self.make_post_request(path, params)
      req = Net::HTTP::Post.new(path)
      req.body = Mieruka.make_params_string(params)
      req.content_type = 'application/x-www-form-urlencoded'
      return req
    end

    def self.make_params_string(params)
      qparam = params.map do |k,v|
        if v.class == Array
          v.map{|e| Mieruka.make_param_string(k, e)}.join('&')
        else
          Mieruka.make_param_string(k, v)
        end
      end
      return qparam.join('&')
    end

    def self.make_param_string(name, value)
      CGI.escape(name.to_s) + '=' + CGI.escape(value.to_s)
    end

    #
    # Authentication Utils
    #
    
    def self.auth_header(token, private_key)
      timestamp = Time.now.to_i.to_s
      nonce = generate_nonce()
      sig = Digest::MD5.hexdigest(private_key + timestamp + nonce)
      "SobaAuth token=\"#{token}\" timestamp=\"#{timestamp}\" nonce=\"#{nonce}\" sig=\"#{sig}\" sigalg=\"SOBA-1\""
    end

    def self.generate_nonce
      charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
      ret = []
      16.times { ret << charset[rand(charset.length)].chr }
      ret.join
    end
    
    def required_params(params, *keys)
      missings = []
      keys.each do |key|
        missings << key unless params.has_key?(key)
      end
      raise "Missing parameters: " + missings.join(',') if missings.size > 0      
    end

  end


end
