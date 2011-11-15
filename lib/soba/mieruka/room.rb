require 'rexml/document'
require 'cgi'

module Soba
  class Mieruka

    class Room
      def initialize(params)
        @id = params['id']
        @name = params['name']
        @description = params['description']
        @owner = params['owner']
        @created_time = Time.at(params['created-time'].to_i / 1000)
        #@deleted_time = params['deleted-time']
        @group = params['group']
        @url = params['url']
      end

      attr_reader :id, :name, :description, :owner, :created_time, :group, :url

      def to_s
        "{id:%d, name:%s, desc:%s, owner:%s, created-time:%s, url:%s}" % [@id, @name, @description, @owner, @created_time, @url]
      end

      def self.create(http_res)
        #Room.elm_to_room(elm_room)
        self.create_from_xml(http_res.body)
      end

      def self.create_from_xml(xml)
        doc = REXML::Document.new(xml)
        ret = []
        doc.elements.each('*/room') do |e|
          ret << Room.elm_to_room(e)
        end
        ret
      end
    
      def self.create_from_room_element(elm)
        return Room.new(parse_room_elm(elm))      
      end

      private
    
      def self.elm_to_room(elm)
        Room.new(parse_room_elm(elm))
      end

      ATTRS = ['id', 'name', 'description', 'owner', 'created-time', 'group', 'url']

      def self.parse_room_elm(elm)
        params = {}
        ATTRS.each do |a|
          begin
            params[a] = CGI.unescapeHTML(elm.elements[a].get_text.to_s)
          rescue
          end
        end
        params
      end
    end

  end
end
