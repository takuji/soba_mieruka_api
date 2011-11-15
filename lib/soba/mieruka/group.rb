require 'rexml/document'
require 'cgi'

module Soba
  class Mieruka

    class Group
      def initialize(params)
        @name = params['name']
        @description = params['description']
      end

      attr_reader :name, :description

      def to_s
        "{name:%s, desc:%s}" % [@name, @description]
      end

      def self.create_from_element(elm)
        return Group.new(parse_group_elm(elm))
      end

      private
    
      ATTRS = ['name', 'description']

      def self.parse_group_elm(elm)
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
