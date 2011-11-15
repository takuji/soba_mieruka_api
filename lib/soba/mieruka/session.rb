require 'rexml/document'
require 'cgi'

module Soba
  class Mieruka

    class Session
      def initialize(params)
        @id = params['id']
        @title = params['title']
        @description = params['description']
        @creator_id = params['creator-id']
        @created_time = params['created-time']
        @deleted_time = params['deleted-time']
        @soba_session_id = params['soba-session-id']
        @scope = params['scope']
        @participants = params['participants']
      end

      attr_reader :id, :title, :description, :creator_id, :created_time, :deleted_time, :soba_session_id, :scope
    
      def self.create(http_res)
        doc = REXML::Document.new(http_res.body)
        ret = []
        doc.elements.each('session-list-response/session-list/session') do |elm|
          ret << Session.elm_to_session(elm)
        end
        ret
      end
    
      def self.create_from_session_element(elm)
        return Session.new(parse_session_elm(elm))
      end
    
   
      private
    
      def self.elm_to_session(elm)
        Session.new(parse_session_elm(elm))
      end

      ATTRS = ['id', 'title', 'description', 'creator-id', 'created-time', 'deleted-time', 'soba-session-id', 'scope']

      def self.parse_session_elm(elm)
        params = {}
        ATTRS.each do |a|
          begin
            params[a] = CGI.unescapeHTML(elm.elements[a].get_text.to_s )
          rescue
          end
        end
        params['participants'] = []
        elm.elements.each('participants/participant') do |partElm|
          params['participants'] << partElm.get_text.to_s
        end
        params
      end
    end

  end
end