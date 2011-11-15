require 'rexml/document'

module Soba
  class Mieruka

    class User
      def initialize(params)
        @name = params['name']
        @id   = params['id']
        @mail = params['mail']
        @groups = params['groups']
      end

      attr_accessor :id, :name, :mail, :groups

      def self.create(http_res)
        doc = REXML::Document.new(http_res.body)
        ret = []
        doc.elements.each('user-list-response/user') do |elm|
          ret << User.create_from_element(elm)
        end
        ret
      end
    
      def self.create_from_element(elm)
        return User.new(parse_user_elm(elm))      
      end

      def to_s
        "{name=#{@name}, mail=#{@mail}, id=#{@id}, groups=#{@groups.join(',')}}"
      end

      private
    
      ATTRS = ['id', 'name', 'mail', 'groups']

      def self.parse_user_elm(elm)
        params = {}
        ATTRS.each do |a|
          if a == 'groups'
            params['groups'] = elm.get_elements('groups/group').map{|e| e.get_text.to_s}
          else
            params[a] = elm.elements[a].get_text.to_s
          end
        end
        params
      end

    end
  end
end
