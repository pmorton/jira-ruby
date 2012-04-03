module JIRA
  class Base
    class Nested < JIRA::Base
      
      # A reference to the parent resource used to initialize this resource.
      attr_reader :parent_resource

      def initialize(client, parent_resource, options = {})
        super(client,options)
        @parent_resource = parent_resource
      end


      # Returns the full path for a collection of this resource.
      # E.g.
      #   JIRA::Resource::Issue.collection_path
      #     # => /jira/rest/api/2/issue/#{id}/worklog
      def self.collection_path(client, parent_resource)

        JIRA::Log.debug parent_resource
        url = ''
        url << client.options[:rest_base_path]
        url << "/"  + parent_resource.class.endpoint_name
        url << "/"  + parent_resource.id
        url << "/"  + self.endpoint_name
        JIRA::Log.debug url
        url
      end

      def self.all(client, parent_resource)
        parent_resource.each do |key, value|
          parent_resource = value
        end

        response = client.get(collection_path(client,parent_resource))
        json = parse_json(response.body)
        if collection_attributes_are_nested
          json = json[endpoint_name.pluralize]
        end
        json.map do |attrs|
          self.new(client, parent_resource, :attrs => attrs, parent_resource.class.endpoint_name.to_sym => parent_resource)
        end  
      end

      # Finds and retrieves a resource with the given ID.
      def self.find(client, key, options = {})
        instance = self.new(client, options)
        instance.attrs[key_attribute.to_s] = key
        instance.fetch
        instance
      end



      # Returns the singular path for the resource with the given key.
      # E.g.
      #   JIRA::Resource::Issue.singular_path('123')
      #     # => /jira/rest/api/2/issue/123
      #
      # If a prefix parameter is provided it will be injected between the base
      # path and the endpoint.
      # E.g.
      #   JIRA::Resource::Comment.singular_path('456','/issue/123/')
      #     # => /jira/rest/api/2/issue/123/comment/456
      def self.singular_path(client, key, parent_resource)
        collection_path(client, parent_resource) + '/' + key
      end

      def url
        prefix = '/'
        unless self.class.belongs_to_relationships.empty?
          prefix = self.class.belongs_to_relationships.inject(prefix) do |prefix_so_far, relationship|
            prefix_so_far + relationship.to_s + "/" + self.send("#{relationship.to_s}_id") + '/'
          end
        end
        if @attrs['self']
          @attrs['self']
        elsif key_value
          self.class.singular_path(client, key_value.to_s, prefix)
        else
          self.class.collection_path(client, parent_resource)
        end
      end

    end
  end
end